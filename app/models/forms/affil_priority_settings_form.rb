module Forms
  class AffilPrioritySettingsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    def mappings=(value)
      rows = value.is_a?(Hash) ? value.values : Array(value)
      @mappings = rows.map { |m| m.to_h.with_indifferent_access }
    end

    def mappings
      @mappings || []
    end

    def initialize(attributes = {})
      super
      self.mappings ||= []
      load_from_settings if attributes.empty?
    end

    validates_each :mappings do |record, attr, value|
      value.each do |m|
        next if m[:affiliation].blank?

        unless (1..5).include?(m[:priority].to_i)
          record.errors.add(attr, "優先度は 1〜5 で入力してください")
        end
      end
    end

    def save
      return false unless valid?

      map = mappings
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
