module ActiveMonitoring
  class Metric < ApplicationRecord
    def self.percentile(value)
      order(:value).offset(count * value / 10 - 1).limit(1).pluck(:value).first
    end
  end
end
