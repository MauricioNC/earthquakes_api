require 'json'
class Api::V1::FeaturesController < ApplicationController
  before_action :set_params
  include Pagy::Backend

  MAGTYPE_FILTERS = ["md", "ml", "ms", "mw", "me", "mi", "mb", "mlg"]

  def index
    if Feature.count > 0
      last_feature = Feature.last.external_id
      fetch_and_save_features(last_feature)
    else
      fetch_and_save_features
    end

    @mag_type.nil? || @mag_type.empty? ? send_normal_response : send_filterd_response
  end

  private

  def send_filterd_response
    response = {}

    if MAGTYPE_FILTERS.include?(@mag_type) && !@mag_type.nil?
      pagy, features = pagy(Feature.where(magType: @mag_type), page: @page, items: @per_page)
      response = prepare_response(features, pagy, @page)
    else
      response = { error: "mag_type '#{@mag_type}' is not valid filter" }
    end

    render json: response
  end

  def send_normal_response
    pagy, features = pagy(Feature.all, page: @page, items: @per_page)
    render json: prepare_response(features, pagy, @page)
  end

  def fetch_and_save_features(last_feature = nil)
    response = Faraday.get('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson')

    json_response = JSON.parse(response.body)['features']

    # Gets the features starting from the last feature inserted
    json_response = json_response.take_while { |feature| feature['id'] != last_feature } unless last_feature.nil?
    json_response = json_response.reverse

    # Remove nil values
    features = sanitize_nil(json_response)

    features.each_with_index do |item, idx|
      feature = item['properties'].slice('place', 'time', 'tsunami', 'magType', 'title')
      feature['external_id'] = item['id']
      feature['magnitude'] = item['properties']['mag']
      feature['longitude'] = item['geometry']['coordinates'][0]
      feature['latitude'] = item['geometry']['coordinates'][1]
      feature['url'] = item['properties']['url']

      Feature.create!(feature)
    end

  rescue Faraday::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def sanitize_nil(data)
    data.reject { |feature| feature["properties"]["magType"].nil? || feature["properties"]["title"].nil? || feature["properties"]["place"].nil? || feature["properties"]["url"].nil? || feature["geometry"]["coordinates"].include?(nil) }
  end

  def prepare_response(features, pagy, page)
    data_response = []

    features.each_with_index do |item, idx|
      feature = {
        data: [
          {
            id: item[:id],
            type: 'feature',
            attributes: {
              external_id: item[:external_id],
              magnitude: item[:magnitude],
              place: item[:place],
              time: item[:time],
              tsunami: item[:tsunami],
              mag_type: item[:magType],
              title: item[:title],
              coordinates: {
                longitude: item[:longitude],
                latitude: item[:latitude],
              }
            },
            links: {
              external_url: item[:url]
            }
          }
        ],
        pagination: {
          current_page: pagy.page,
          total: pagy.count,
          per_page: pagy.items,
          last_page: pagy.last
        }
      }
      data_response.push(feature)
    end
    data_response
  end

  def set_params
    @page = params[:page] || Pagy::DEFAULT[:page]
    @per_page = params[:per_page] || Pagy::DEFAULT[:items]
    @mag_type = params[:mag_type]
  end
end
