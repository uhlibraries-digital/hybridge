class SearchBuilder < Hyrax::CollectionSearchBuilder
  def sort_field
    "system_create_dtsi"
  end
end