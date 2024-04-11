require 'json'
class Api::V1::FeaturesController < ApplicationController
  include Pagy::Backend

  def index
    if Feature.count > 0
      last_feature = Feature.last.external_id
      fetch_and_save_features(last_feature)
    else
      fetch_and_save_features
    end

    page = params[:page] || Pagy::DEFAULT[:page]
    per_page = params[:per_page] || Pagy::DEFAULT[:items]

    pagy, features = pagy(Feature.all, page: page, items: per_page)
    features = prepare_response(features, pagy, page)

    render json: features
  end

  private

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
          per_page: pagy.items
        }
      }
      data_response.push(feature)
    end
    data_response
  end
end
