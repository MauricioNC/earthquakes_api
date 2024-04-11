require 'json'

class Api::V1::FeaturesController < ApplicationController

  def index
    if Feature.count > 0
      last_feature = Feature.first.external_id
      fetch_and_save_features(last_feature)
    else
      fetch_and_save_features
    end

    features = Feature.all
    features = prepare_response(features)

    render json: features
  end

  private

  def fetch_and_save_features(last_feature = nil)
    response = Faraday.get('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson')

    json_response = JSON.parse(response.body)['features']
    json_response = json_response.take_while { |feature| feature['id'] != last_feature } unless last_feature.nil?

    features = sanitize_nil(json_response)

    features.each_with_index do |item, idx|
      feature = item['properties'].slice('place', 'time', 'tsunami', 'magType', 'title')
      feature['external_id'] = item['id']
      feature['magnitude'] = item['properties']['mag']
      feature['longitude'] = item['geometry']['coordinates'][0]
      feature['latitude'] = item['geometry']['coordinates'][1]
      feature['url'] = item['properties']['url']
      begin
        Feature.create!(feature)
      rescue ActiveRecord::RecordInvalid => e
        next
      end
    end

  rescue Faraday::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def sanitize_nil(data)
    data.reject { |feature| feature["properties"]["magType"].nil? || feature["properties"]["title"].nil? || feature["properties"]["place"].nil? || feature["properties"]["url"].nil? || feature["geometry"]["coordinates"].include?(nil) }
  end

  def prepare_response(features)
    data_response = []

    features.each_with_index do |item, idx|
      feature = {
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
      data_response.push(feature)
    end
    data_response
  end
end
