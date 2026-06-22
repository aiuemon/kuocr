module Forms
  class AffilPrioritySettingsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :mappings

    def initialize(attributes = {})
      super
      self.mappings ||= []
      load_from_settings if attributes.empty?
    end

    validates_each :mappings do |record, attr, value|
      Array(value).each do |m|
        next if m[:affiliation].blank?

        unless (1..5).include?(m[:priority].to_i)
          record.errors.add(attr, "優先度は 1〜5 で入力してください")
        end
      end
    end

    def save
      return false unless valid?

      map = Array(mappings)
        .reject { |m| m[:affiliation].blank? }
        .to_h { |m| [ m[:affiliation].strip, m[:priority].to_i ] }
      Setting.affiliation_priority_map = map
      true
    rescue => e
      errors.add(:base, e.message)
      false
    end

    def persisted?
      true
    end

    def to_key
      [ :affil_priority_settings ]
    end

    def model_name
      ActiveModel::Name.new(self, nil, "AffilPrioritySettings")
    end

    private

    def load_from_settings
      self.mappings = Setting.affiliation_priority_map.map do |aff, pri|
        { affiliation: aff, priority: pri.to_s }
      end
    end
  end
end
