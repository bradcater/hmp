module HasManyPartitionable
  require 'active_support'
  extend ActiveSupport::Concern
  included do
    class_eval do
      def self.has_one_partitionable(name, opts={})
        opts = opts.dup
        class_name = opts.delete(:class_name) || name.to_s.gsub(/^[^_]+_/, '').camelize
        partition_limit = opts.delete(:partition_limit) || 1
        foreign_key = opts.delete(:foreign_key) || "#{self.table_name.singularize}_id"
        partition_order = opts.delete(:partition_order) || 'id DESC'
        conditions = opts.delete(:conditions)
        join_conditions = proc { 
          if self.respond_to?(:id)
            "#{foreign_key} = #{id}"
          else
            "#{foreign_key} IN (#{self.instance_variable_get('@record_ids').map(&:to_s).join(',')})"
          end
        }
        has_many class_name.underscore.pluralize, opts
        has_one "#{name}_fast", :class_name => class_name, :order => 'id DESC'
        has_one name, opts.merge({
          :class_name => class_name,
          :conditions => proc { %{
            #{class_name.constantize.quoted_table_name}.id IN (
              WITH t AS (
                SELECT
                  id,
                  ROW_NUMBER() OVER (
                    PARTITION BY #{foreign_key} ORDER BY #{partition_order}
                  ) AS rank
                FROM #{class_name.constantize.quoted_table_name} #{class_name.constantize.table_name}
                WHERE #{(self.respond_to?(:id) ? self.class : self).send(:sanitize_sql, instance_eval(&join_conditions))}
                  #{conditions.is_a?(Proc) ? "AND #{self.class.send(:sanitize_sql, instance_eval(&conditions))}" : nil}
                  #{conditions.is_a?(Array) || conditions.is_a?(String) ? "AND #{self.class.send(:sanitize_sql, conditions)}" : nil}
              )
              SELECT id
              FROM t
              WHERE rank = 1
            )
          } }
        })
      end
    end
  end
end
