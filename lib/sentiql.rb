require "mysql2"

module SentiQL

  class Base
    attr_accessor :attrs, :errors

    def initialize attrs={}
      @attrs = {}
      @errors = {}
      attrs.each_pair do |key, value|
        @attrs[key] = value
      end
    end

    def [] key
      @attrs ||= {}
      @attrs[key]
    end

    def []=(key, value)
      @attrs ||= {}
      @attrs[key] = value
    end


    def save

      filter_with :before_save_filters

      if @attrs[:id]

        self[:updated_at] = Time.now

        i = @attrs.select { |k| self.class.schema.include?(k) }     
        values = i.keys.map { |k| @attrs[k] }
        values << @attrs[:id]

        return self unless valid?


        SentiQL::Base.execute "UPDATE #{self.class.table} SET #{i.keys.map{|m| "#{m.to_s}=?"}.join(",")} WHERE id=?", values

      else

        filter_with :before_create_filters

        self[:created_at] = Time.now
        self[:updated_at] = Time.now

        i = @attrs.select { |k| self.class.schema.include?(k) }
        values = i.keys.map { |k| @attrs[k] }

        return self unless valid?

        id = SentiQL::Base.insert "INSERT INTO #{self.class.table} (#{i.keys.map{|k| k.to_s}.join(",")}) VALUES (#{i.map{|k| k="?"}.join(",")})", values
        @attrs[:id] = id
        
        filter_with :after_create_filters
      end
      
      filter_with :after_save_filters

      return self
    end

    def filter_with filter
      self.class.send(filter).each do |f|
        self.send f
      end
    end

    def method_missing method_id, *args
      if @attrs.has_key? method_id
        return @attrs[method_id.to_sym]
      else
        super
      end
    end

    def valid?; true; end
      
    class << self
      def connection; @@connection; end
      def connection=(value); @@connection = value; end
      
      def set_schema *args; @schema = args; end
      def schema; @schema; end

      def before_save *args; @before_save_filters = args; end 
      def before_save_filters; @before_save_filters ||={} ; end
      def before_create *args; @before_create_filters = args; end 
      def before_create_filters; @before_create_filters ||={}; end
      def after_create *args; @after_create_filters = args; end 
      def after_create_filters; @after_create_filters ||={}; end
      def after_save *args; @after_save_filters= args; end 
      def after_save_filters; @after_save_filters ||={}; end

      def set_table name; @table= name.to_s; end
      def table; @table.to_sym; end


      def create hash
        obj = self.new hash
        return obj.save
      end

      def find_by hash
        field_name = hash.keys.first.to_s
        value = hash.values.first
        r = first "SELECT * FROM #{self.table} WHERE #{field_name}=? LIMIT 1", [value]
        return r ? self.new(r) : nil
      end

      def first sql, args=[]
        results = self.execute sql, args
        return results.nil? ? nil : results.first
      end

      def insert sql, args=[]
        execute sql, args
        connection.last_id
      end

      def execute sql, args=[]
        esced = args.map { |v| connection.escape(v.to_s) }
        ix = 0
        escq = sql.gsub(/\?/) do |m|
          raise Mysql2::Error.new("Not enough arguments for prepared statement") if ix >= esced.count
          val = esced[ix]
          ix += 1
          "'#{val}'"
        end
        raise Mysql2::Error.new("Too many arguments for prepared statement (required: #{ix}, passed: #{esced.count})") if ix < esced.count
        return connection.query escq     
      end

      alias :all :execute

    end

  end

end
