class Item < ApplicationRecord
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name sku price active date_added]
  end
end
