require 'test_helper'

class WidgetListTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    Item.delete_all
    12.times do |i|
      Item.create!(name: i.even? ? 'Apple' : 'Banana', sku: 1000 + i,
                   price: i + 1, active: 'Yes', date_added: Date.today)
    end
  end

  teardown { Item.delete_all }

  test 'Sequel list renders SQLite rows and pagination' do
    get root_path
    assert_response :success
    assert_select 'h1', text: 'Data, in a new light.'
    assert_select 'link[href*="widget_list_theme_ai"]'
    assert_select 'table.widget_list.wl-ai-table'
    assert_select 'a[href=?]', administration_path
    assert_select 'td', text: 'Apple'
    assert_match 'Total 12 records found', response.body
  end

  test 'Sequel Ajax search filters by SKU' do
    post root_path, params: { BUTTON_VALUE: 'templateListJump', LIST_NAME: 'items', search_filter: '1001' }
    assert_response :success
    data = response.parsed_body
    assert_includes data.fetch('list'), 'Banana'
    assert_includes data.fetch('list'), '1001'
    refute_includes data.fetch('list'), '1002'
  end

  test 'Sequel Ajax pagination advances to the requested page' do
    post root_path, params: { BUTTON_VALUE: 'templateListJump', LIST_NAME: 'items', LIST_SEQUENCE: '2' }
    assert_response :success
    list = response.parsed_body.fetch('list')
    assert_includes list, '1010'
    refute_includes list, '1000'
  end

  test 'Ransack filters Active Record results' do
    get ransack_path, params: { q: { name_cont: 'Apple' } }
    assert_response :success
    assert_select 'table.widget_list'
    assert_select 'a[href=?]', administration_path
    assert_includes response.body, 'Apple'
    refute_includes response.body, '<span  style="" onclick="">Banana</span>'
    assert_match 'Total 6 records found', response.body
  end

  test 'exports a CSV from the Sequel list' do
    get root_path, params: { BUTTON_VALUE: 'templateListJump', LIST_NAME: 'items', export_widget_list: '1' }
    assert_response :success
    assert_equal 'text/csv', response.media_type
    assert_includes response.body, 'Apple'
  end

  test 'administration console renders its setup wizard' do
    get administration_path
    assert_response :success
    assert_select 'form#widget_list_administration'
    assert_includes response.body, 'Step One - Start'
  end

  test 'administration console loads model fields over Ajax' do
    post administration_path, params: { ajax: '1', model: 'Item' }
    assert_response :success
    assert_includes response.parsed_body.fetch('fields'), 'name'
  end

  test 'administration previews a model and generates Rails 8 controller code' do
    files = %w[widget-list-administration.json widget-list-administration-all.json].map do |name|
      Rails.root.join('config', name)
    end
    originals = files.to_h { |path| [path, path.exist? ? path.binread : nil] }
    configuration = {
      name: 'item_listing', view: 'Item', desiredController: 'widget_list_examples',
      desiredAction: 'item_listing', title: 'Items', listDescription: 'Showing Items',
      noDataMessage: 'No Items', searchTitle: 'Search items', rowLimit: '10', showPagination: '1',
      showSearch: '1', useRansack: '1', useSort: '1',
      fields: { key: %w[id name], description: %w[ID Name] }
    }

    post administration_path, params: configuration.merge(ajax: '1', save: '1')
    assert_response :success

    get administration_path, params: {
      iframe: '1', desiredController: 'widget_list_examples', desiredAction: 'item_listing'
    }
    assert_response :success
    assert_select 'table.widget_list'
    assert_includes response.body, 'Apple'

    post administration_path, params: configuration
    assert_response :success
    assert_includes response.body, 'Item.ransack(params[:q])'
    assert_includes response.body, 'render json: JSON.parse(output)'
  ensure
    originals&.each do |path, contents|
      if contents
        path.binwrite(contents)
      elsif path.exist?
        path.delete
      end
    end
  end

  test 'administration drill-down Ajax filters by the selected column' do
    files = %w[widget-list-administration.json widget-list-administration-all.json].map do |name|
      Rails.root.join('config', name)
    end
    originals = files.to_h { |path| [path, path.exist? ? path.binread : nil] }
    configuration = {
      name: 'item_listing', view: 'Item', desiredController: 'widget_list_examples',
      desiredAction: 'item_listing', title: 'Items', listDescription: 'Showing Items',
      noDataMessage: 'No Items', rowLimit: '10', showPagination: '1',
      fields: { key: %w[id name_linked], description: %w[ID Name] },
      fields_hidden: { key: ['name'] }, drillDownsOn: '1',
      drill_downs: {
        drill_down_name: ['filter_by_name'], data_to_pass_from_view: ['name'],
        column_to_show: ['name_linked']
      }
    }

    post administration_path, params: configuration.merge(ajax: '1', save: '1')
    assert_response :success

    post administration_path, params: {
      iframe: '1', BUTTON_VALUE: 'templateListJump', LIST_NAME: 'item_listing',
      desiredController: 'widget_list_examples', desiredAction: 'item_listing',
      drill_down: 'filter_by_name', filter: 'Apple'
    }
    assert_response :success
    assert_equal 'application/json', response.media_type
    assert_includes response.parsed_body.fetch('list'), 'Apple'
    refute_includes response.parsed_body.fetch('list'), 'Banana'

    post administration_path, params: {
      iframe: '1', BUTTON_VALUE: 'templateListJump', LIST_NAME: 'item_listing',
      desiredController: 'widget_list_examples', desiredAction: 'item_listing',
      searchClear: '1'
    }
    assert_response :success
    jump_url = Nokogiri::HTML.fragment(response.parsed_body.fetch('list'))
                       .at_css('#item_listing_jump_url')['value']
    query = Rack::Utils.parse_query(URI.parse(jump_url).query)
    assert_equal '1', query['iframe']
    assert_equal 'widget_list_examples', query['desiredController']
    assert_equal 'item_listing', query['desiredAction']

    post "#{jump_url}&drill_down=filter_by_name&filter=Banana"
    assert_response :success
    assert_includes response.parsed_body.fetch('list'), 'Banana'
    refute_includes response.parsed_body.fetch('list'), 'Apple'
  ensure
    originals&.each do |path, contents|
      if contents
        path.binwrite(contents)
      elsif path.exist?
        path.delete
      end
    end
  end
end
