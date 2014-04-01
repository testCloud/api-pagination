require 'api-pagination/hooks'
require 'api-pagination/version'

module ApiPagination
  class << self
    attr_reader :paginator, :sunspot

    def paginate(collection, options = {}, &block)
      options[:page]     ||= 1
      options[:per_page] ||= 10

      case ApiPagination.paginator
      when :kaminari
        collection.page(options[:page]).per(options[:per_page]).tap(&block)
      when :will_paginate
        collection.paginate(:page => options[:page], :per_page => options[:per_page]).tap(&block)
      end
    end

    def paginate_method(collection_object, the_method, method_params, options, &block)
      options[:page]     ||= 1
      options[:per_page] ||= 10
      method_params.merge!( options.slice(:page, :per_page) )
      collection_object.send(the_method, method_params).tap(&block)
    end

    def pages_from(collection)
      {}.tap do |pages|
        unless collection.first_page?
          pages[:first] = 1
          pages[:prev]  = collection.current_page - 1
        end

        unless collection.last_page?
          pages[:last] = collection.total_pages
          pages[:next] = collection.current_page + 1
        end
      end
    end

    def total_from(collection)
      if ApiPagination.sunspot && collection.is_a?(Sunspot::Search::PaginatedCollection)
        collection.total.to_s
      else
        case ApiPagination.paginator
          when :kaminari      then collection.total_count.to_s
          when :will_paginate then collection.total_entries.to_s
        end
      end
    end

    def pagination_header_from(collection)
      {
        total: ApiPagination.total_from(collection),
        total_pages: collection.total_pages,
        page: (collection.previous_page||0) + 1,
        first_page: collection.first_page?,
        last_page: collection.last_page?,
        previous_page: collection.previous_page,
        next_page: collection.next_page
      }.to_s
    end
  end
end

ApiPagination::Hooks.init
