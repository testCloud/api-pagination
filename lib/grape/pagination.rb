module Grape
  module Pagination
    def self.included(base)
      Grape::Endpoint.class_eval do
        def paginate(collection, the_method=nil, the_params={})
          block = Proc.new do |collection|
            links = (header['Link'] || "").split(',').map(&:strip)
            url   = request.url.sub(/\?.*$/, '')
            pages = ApiPagination.pages_from(collection)

            pages.each do |k, v|
              old_params = Rack::Utils.parse_query(request.query_string)
              new_params = old_params.merge('page' => v)
              links << %(<#{url}?#{new_params.to_param}>; rel="#{k}")
            end

            header 'Link', links.join(', ') unless links.empty?
            header 'Total', ApiPagination.total_from(collection)
            header 'X-Pagination', ApiPagination.pagination_header_from(collection)
          end

          if the_method.nil?
            ApiPagination.paginate(collection, params, &block)
          else
            ApiPagination.paginate_method(collection, the_method, the_params, params, &block)
          end
        end
      end

      base.class_eval do
        def self.paginate(options = {})
          options.reverse_merge!(:per_page => 10)
          params do
            optional :page,     :type => Integer, :default => 1,
                                :desc => 'Page of results to fetch.'
            optional :per_page, :type => Integer, :default => options[:per_page],
                                :desc => 'Number of results to return per page.'
          end
        end
      end
    end
  end
end
