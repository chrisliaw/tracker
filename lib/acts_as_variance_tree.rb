
# override some essential part of acts_as_tree to support multiple parent column

module ActsAsTree
  module ClassMethods
    #class << self
      def acts_as_tree(options = {})

        puts "Overridden"
        configuration = {
          foreign_key:   "parent_id",
          order:         nil,
          counter_cache: nil,
          dependent:     :destroy,
          parent_name:   "parent",
          children_name: "children",
          prefix: ""
        }

        configuration.update(options) if options.is_a?(Hash)

        #belongs_to :parent, class_name:    name,
        #  foreign_key:   configuration[:foreign_key],
        #  counter_cache: configuration[:counter_cache],
        #  inverse_of:    :children

        #has_many :children, class_name:  name,
        #  foreign_key: configuration[:foreign_key],
        #  order:       configuration[:order],
        #  dependent:   configuration[:dependent],
        #  inverse_of:  :parent

        belongs_to configuration[:parent_name].to_sym, class_name: name,
          foreign_key:   configuration[:foreign_key],
          counter_cache: configuration[:counter_cache],
          inverse_of:    configuration[:children_name].to_sym

        has_many configuration[:children_name].to_sym, class_name: name,
          foreign_key: configuration[:foreign_key],
          order:       configuration[:order],
          dependent:   configuration[:dependent],
          inverse_of:  configuration[:parent_name].to_sym


        class_eval <<-EOV
        include ActsAsTree::InstanceMethods
        
        @@config = configuration
        after_update :update_parents_counter_cache

        def self.#{configuration[:prefix]}roots
          order_option = %Q{#{configuration.fetch :order, "nil"}}
          where(:#{configuration[:foreign_key]} => nil).order(order_option)
        end

        def self.#{configuration[:prefix]}root
          order_option = %Q{#{configuration.fetch :order, "nil"}}
          self.roots.first
        end

        def self.config
          @@config
        end
        EOV

      end
    #end

  end

  module InstanceMethods

    def initialize(*args)
      #puts "Args #{args}"
      super(*args)
      instance_eval <<-EOD
      def #{self.class.config[:prefix]}ancestors
        node, nodes = self, []
        #nodes << node = node.parent while node.parent
        nodes << node = node.send(self.class.config[:parent_name]) while node.send(self.class.config[:parent_name])
        nodes
      end

      # Returns the root node of the tree.
      def #{self.class.config[:prefix]}root
        node = self
        #node = node.parent while node.parent
        node = node.send(self.class.config[:parent_name]) while node.send(self.class.config[:parent_name])
        node
      end

      # Returns all siblings of the current node.
      #
      #   subchild1.siblings # => [subchild2]
      def #{self.class.config[:prefix]}siblings
        self_and_siblings - [self]
      end

      # Returns all siblings and a reference to the current node.
      #
      #   subchild1.self_and_siblings # => [subchild1, subchild2]
      def #{self.class.config[:prefix]}self_and_siblings
        self.send(self.class.config[:parent_name]) ? self.send(self.class.config[:parent_name]).send(self.class.config[:children_name]) : self.class.roots
      end

      # Returns children (without subchildren) and current node itself.
      #
      #   root.self_and_children # => [root, child1]
      def #{self.class.config[:prefix]}self_and_children
        [self] + self.send(self.class.config[:children_name])
      end

      # Returns ancestors and current node itself.
      #
      #   subchild1.self_and_ancestors # => [subchild1, child1, root]
      def #{self.class.config[:prefix]}self_and_ancestors
        [self] + self.ancestors
      end

      EOD
    end
    # Returns list of ancestors, starting from parent until root.
    #
    #   subchild1.ancestors # => [child1, root]
    #def ancestors
    #  node, nodes = self, []
    #  #nodes << node = node.parent while node.parent
    #  nodes << node = node.send(self.class.config[:parent_name]) while node.send(self.class.config[:parent_name])
    #  nodes
    #end

    ## Returns the root node of the tree.
    #def root
    #  node = self
    #  #node = node.parent while node.parent
    #  node = node.send(self.class.config[:parent_name]) while node.send(self.class.config[:parent_name])
    #  node
    #end

    ## Returns all siblings of the current node.
    ##
    ##   subchild1.siblings # => [subchild2]
    ##def siblings
    ##  self_and_siblings - [self]
    ##end

    ## Returns all siblings and a reference to the current node.
    ##
    ##   subchild1.self_and_siblings # => [subchild1, subchild2]
    #def self_and_siblings
    #  self.send(self.class.config[:parent_name]) ? self.send(self.class.config[:parent_name]).send(self.class.config[:children_name]) : self.class.roots
    #end

    ## Returns children (without subchildren) and current node itself.
    ##
    ##   root.self_and_children # => [root, child1]
    #def self_and_children
    #  [self] + self.send(self.class.config[:children_name])
    #end

    ## Returns ancestors and current node itself.
    ##
    ##   subchild1.self_and_ancestors # => [subchild1, child1, root]
    ##def self_and_ancestors
    ##  [self] + self.ancestors
    ##end

    private

    def update_parents_counter_cache
      if self.respond_to?(:children_count) && parent_id_changed?
        self.class.decrement_counter(:children_count, parent_id_was)
        self.class.increment_counter(:children_count, parent_id)
      end
    end

  end
end
