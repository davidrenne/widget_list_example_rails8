class ItemsController < ApplicationController
  def index
    list = base_list
    list['database'] = 'primary'
    list['view'] = 'items'
    list['listDescription'] = 'SQLite records through Sequel 5.109.0'
    render_list(list)
  end

  def ransack
    list = base_list
    list['database'] = 'secondary'
    list['title'] = 'Ransack inventory'
    list['listDescription'] = 'Active Record filtered by Ransack 5.0.2'
    list['ransackSearch'] = Item.ransack(params[:q])
    list['view'] = list['ransackSearch'].result
    render_list(list)
  end

  private

  def base_list
    list = WidgetList::List.init_config
    list['name'] = action_name == 'ransack' ? 'ransack_items' : 'items'
    list['title'] = 'Inventory'
    list['fields'] = { 'id' => 'ID', 'name' => 'Name', 'sku' => 'SKU', 'price' => 'Price', 'active' => 'Active', 'date_added' => 'Added' }
    list['orderBy'] = 'id'
    list['rowLimit'] = 10
    list['searchIdCol'] = ['id', 'sku']
    list['noDataMessage'] = 'No items found'
    list
  end

  def render_list(list)
    type, output = WidgetList::List.build_list(list)
    case type
    when 'html' then @output = output
    when 'json' then render json: JSON.parse(output)
    when 'export' then send_data output, filename: 'items.csv', type: 'text/csv'
    end
  end
end
