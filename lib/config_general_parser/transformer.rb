module ConfigGeneralParser
  class Transformer < Parslet::Transform

    rule(key: simple(:key), val: subtree(:val)) do
      { key => val }
    end

    rule(:block => { :type => simple(:type),
                     :name => simple(:sub),
                     :values => subtree(:values)}) do |dict|
      type = dict[:type].to_s
      sub = dict[:sub].to_s
      values = dict[:values]
      v = values.inject({}, &method(:merge_options))
      if !sub.empty?
        { type => { sub => v }}
      else
        { type => v }
      end
    end

    rule(:document => subtree(:options)) do |dict|
      options = dict[:options]
      options.inject({}, &method(:merge_options))
    end

    def self.merge_options(existing, updates)
      updates.each do |key, value|
        k = key.to_s
        if existing.has_key?(k)
          existing[k] = merge_value(existing[k], value)
        else
          if value.kind_of?(Hash)
            existing[k] = merge_options({}, value)
          else
            existing[k] = value
          end
        end
      end
      existing
    end

    def self.merge_value(target, value)
      if target.kind_of?(Hash) && value.kind_of?(Hash)
        merge_options(target, value)
      elsif target.kind_of?(Array) && value.kind_of?(Hash)
        merge_into_array(target, value)
      else
        [ target, value ].flatten
      end
    end

    def self.merge_into_array(existing, update)
      existing.map! do |item|
        if item.kind_of?(Hash)
          item.keys.map! do |i|
            if update.keys.include?(i)
              item[i] = merge_value(item[i], update.delete(i))
            end
          end
        else
          if update.keys.include?(item)
            item = {item => update.delete(item)}
          end
        end
        item
      end
      update.empty? ? existing : existing << update
    end

  end
end
