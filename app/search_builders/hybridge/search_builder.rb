module Hybridge
  class SearchBuilder < Hyrax::CollectionSearchBuilder

    def add_sorting_to_solr(solr_parameters)
      return if solr_parameters[:q]
      solr_parameters[:sort] ||= "system_create_dtsi desc"
    end

  end
end