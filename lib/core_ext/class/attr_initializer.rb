class Class
  def attr_initializer(*attrs)
    attr_reader *attrs

    define_method :initialize do |*values, &block|
      unless values.size == attrs.size
        raise ArgumentError, "wrong number of arguments (#{values.size} for #{attrs.size})"
      end

      attrs.each_with_index do |attr, ix|
        instance_variable_set(:"@#{attr}", values[ix])
      end
    end

    # Jruby doesn't support Module.prepend, yet :(
    # https://github.com/jruby/jruby/issues/751
    #
    # prepend Module.new {
    #   define_method :initialize do |*values, &block|
    #     if values.size < attrs.size
    #       raise ArgumentError, "wrong number of arguments (#{values.size} for #{attrs.size})"
    #     end
    #
    #     attrs.each_with_index do |attr, ix|
    #       instance_variable_set(:"@#{attr}", values[ix])
    #     end
    #
    #     super(*values, &block)
    #   end
    # }
    #
    # define_method(:initialize) { |*| }
  end
end
