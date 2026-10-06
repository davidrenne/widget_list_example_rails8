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
    assert_select 'h1', text: 'widget_list on Rails 8.1.4'
    assert_select 'table.widget_list'
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

  test 'Ransack filters Active Record results' do
    get ransack_path, params: { q: { name_cont: 'Apple' } }
    assert_response :success
    assert_select 'table.widget_list'
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
end
