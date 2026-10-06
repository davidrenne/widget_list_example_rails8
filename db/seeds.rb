Item.delete_all
25.times do |i|
  Item.create!(name: %w[Apple Banana Cherry Date Elderberry Fig Grape][i % 7],
               price: (i + 1) * 1.25, sku: 1000 + i,
               active: i.even? ? 'Yes' : 'No', date_added: Date.today - i)
end
