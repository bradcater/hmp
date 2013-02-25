module ActiveRecord
  class Relation
    def to_a
      return @records if loaded?

      @records = eager_loading? ? find_with_associations : @klass.find_by_sql(arel.to_sql)

      # HMP
      @klass.send(:instance_variable_set, :@record_ids, @records.map(&:id))
      # END HMP

      preload = @preload_values
      preload +=  @includes_values unless eager_loading?
      preload.each {|associations| @klass.send(:preload_associations, @records, associations) }

      # HMP
      @klass.send(:instance_variable_set, :@record_ids, nil)
      # END HMP

      # @readonly_value is true only if set explicitly. @implicit_readonly is true if there
      # are JOINS and no explicit SELECT.
      readonly = @readonly_value.nil? ? @implicit_readonly : @readonly_value
      @records.each { |record| record.readonly! } if readonly

      @loaded = true
      @records
    end
  end
end
