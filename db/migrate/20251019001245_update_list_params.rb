class UpdateListParams < ActiveRecord::Migration[6.1]

  class List < ActiveRecord::Base
    self.table_name = 'lists'
  end

  def change
    say_with_time "Converting include_keywords and exclude_keywords to single list format" do
      List.find_each(batch_size: 100) do |list|
        new_inc = convert_nested_to_single(list.read_attribute(:include_keywords))
        new_exc = convert_nested_to_single(list.read_attribute(:exclude_keywords))

        updates = {}
        updates[:include_keywords] = new_inc if new_inc != list.read_attribute(:include_keywords)
        updates[:exclude_keywords] = new_exc if new_exc != list.read_attribute(:exclude_keywords)

        next if updates.empty?
        list.update_columns(updates)
      end
    end
  end

  private

  def convert_nested_to_single(value)
    return value if value.nil?
    return value unless value.is_a?(Array)

    result = []

    value.each do |elem|
      if elem.is_a?(Array)
        next if elem.empty?
        lookaheads = elem.map { |t| "(?=.*#{Regexp.escape(t.to_s)})" }.join
        regex_str = "/#{lookaheads}/"
        result << regex_str
      else
        result << elem
      end
    end

    result
  end
end
