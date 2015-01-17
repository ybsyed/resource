require 'support/spec_support'
require 'crazytown/chef/struct_resource'

describe Crazytown::Chef::StructResource do
  def self.with_struct(name, &block)
    before :each do
      Object.send(:remove_const, name) if Object.const_defined?(name, false)
      eval "class ::#{name} < Crazytown::Chef::StructResource; end"
      Object.const_get(name).class_eval(&block)
    end
    after :each do
    end
  end

  context "When MyResource is a ResourceStruct with two attributes" do
    with_struct(:MyResource) do
      attribute :x
      attribute :y
    end
    it "You can create a new MyResource" do
      expect(MyResource.open).to be_kind_of(MyResource)
    end
    it "You can set and get attributes" do
      r = MyResource.open
      expect(r.x).to be_nil
      expect(r.y).to be_nil
      expect(r.x = 10).to eq 10
      expect(r.y = 20).to eq 20
      expect(r.x).to eq 10
      expect(r.y).to eq 20
    end
  end

  # context "When MyResource is a ResourceStruct with attribute :x, default: 15" do
  #   with_struct(:MyResource) do
  #     attribute :x, default: 15
  #   end
  #   it "x returns the default if not set" do
  #     r = MyResource.open
  #     expect(r.x).to eq 15
  #   end
  #   it "x returns the new value if it is set" do
  #     r = MyResource.open
  #     expect(r.x).to eq 15
  #     expect(r.x = 20).to eq 20
  #     expect(r.x).to eq 20
  #   end
  # end

  # context "When MyResource is a ResourceStruct with attribute :x, 15 and attribute :y { x*2 }" do
  #   with_struct(:MyResource) do
  #     attribute :x, default: 15
  #     attribute :y do
  #       x*2
  #     end
  #   end
  #   it "x and y return the default if not set" do
  #     r = MyResource.open
  #     expect(r.x).to eq 15
  #     expect(r.y).to eq 30
  #   end
  #   it "y returns the new value if it is set" do
  #     r = MyResource.open
  #     expect(r.y).to eq 30
  #     expect(r.y = 20).to eq 20
  #     expect(r.y).to eq 20
  #   end
  #   it "y returns a value based on x if x is set" do
  #     r = MyResource.open
  #     expect(r.y).to eq 30
  #     expect(r.x = 20).to eq 20
  #     expect(r.y).to eq 40
  #   end
  # end

  context "When MyResource is a ResourceStruct with attribute :x, ResourceStruct" do
    with_struct(:MyResource) do
      attribute :x, MyResource
      attribute :y
    end
    it "x and y can be set to a resource" do
      r = MyResource.open
      r.y = 10
      expect(r.x).to be_nil
      r2 = MyResource.open
      expect(r2.x = r).to eq r
      r2.y = 20
      expect(r2.x).to eq r
      expect(r2.x.y).to eq 10
    end
  end

  context "When MyResource has attribute :x, identity: true" do
    with_struct(:MyResource) do
      attribute :x, identity: true
      attribute :y
    end
    it "open() fails with 'x is required'" do
      expect { MyResource.open() }.to raise_error ArgumentError
    end
    it "open(1) creates a MyResource where x = 1" do
      expect(r = MyResource.open(1)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to be_nil
    end
    it "open(x: 1) creates a MyResource where x = 1" do
      expect(r = MyResource.open(x: 1)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to be_nil
    end
    it "open(1, 2) fails with too many arguments" do
      expect { MyResource.open(1, 2) }.to raise_error ArgumentError
    end
  end

  context "When MyResource has attribute :x, identity: true, required: false" do
    with_struct(:MyResource) do
      attribute :x, identity: true, required: false
      attribute :y
    end
    it "open() creates a MyResource where x = nil" do
      expect(r = MyResource.open()).to be_kind_of(MyResource)
      expect(r.x).to be_nil
      expect(r.y).to be_nil
    end
    it "open(1) fails with 'too many arguments'" do
      expect { MyResource.open(1) }.to raise_error ArgumentError
    end
    it "open(x: 1) creates a MyResource where x = 1" do
      expect(r = MyResource.open(x: 1)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to be_nil
    end
  end

  context "When MyResource has attribute :x and :y, identity: true" do
    with_struct(:MyResource) do
      attribute :x, identity: true
      attribute :y, identity: true
      attribute :z
    end
    it "open() fails with 'x is required'" do
      expect { MyResource.open() }.to raise_error ArgumentError
    end
    it "open(1) fails with 'y is required'" do
      expect { MyResource.open(1) }.to raise_error ArgumentError
    end
    it "open(y: 1) fails with 'x is required'" do
      expect { MyResource.open(y: 1) }.to raise_error ArgumentError
    end
    it "open(1, 2) creates a MyResource where x = 1 and y = 2" do
      expect(r = MyResource.open(1, 2)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to eq 2
      expect(r.z).to be_nil
    end
    it "open(1, 2, 3) fails with too many arguments" do
      expect { MyResource.open(1, 2, 3) }.to raise_error ArgumentError
    end
    it "open(x: 1, y: 2) creates MyResource.x = 1, y = 2" do
      expect(r = MyResource.open(x: 1, y: 2)).to be_kind_of(MyResource)
      expect(r.x).to eq 1
      expect(r.y).to eq 2
      expect(r.z).to be_nil
    end
    it "open(3, 4, x: 1, y: 2) creates MyResource.x = 3, y = 4" do
      expect { MyResource.open(3, 4, x: 1, y: 2) }.to raise_error ArgumentError
    end
  end

  context "When MyResource has identity attributes x and y, and x is not required" do
    with_struct(:MyResource) do
      attribute :x, identity: true, required: false
      attribute :y, identity: true
    end
    it "open() fails with y is required" do
      expect { MyResource.open() }.to raise_error ArgumentError
    end
    it "open(1) creates a MyResource where x = nil and y = 1" do
      expect(r = MyResource.open(1)).to be_kind_of(MyResource)
      expect(r.x).to be_nil
      expect(r.y).to eq 1
    end
    it "open(1, 2) fails with 'too many arguments'" do
      expect { MyResource.open(1, 2) }.to raise_error ArgumentError
    end
    it "open(y: 1) creates a MyResource where x = nil and y = 1" do
      expect(r = MyResource.open(y: 1)).to be_kind_of(MyResource)
      expect(r.x).to be_nil
      expect(r.y).to eq 1
    end
  end

  describe :coercion do
    context "With a struct with x, y and z" do
    end
  end

  describe :load do
    context "When load sets y to x*2 and z to x*3" do
      with_struct(:MyResource) do
        attribute :x, identity: true
        attribute :y
        attribute :z
        attribute :num_loads
        def load
          y x*2
          z x*3
          self.num_loads ||= 0
          self.num_loads += 1
        end
      end

      it "MyResource.open(1).y == 2 and .z == 3" do
        r = MyResource.open(1)
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
      end

      it "load is only called once" do
        r = MyResource.open(1)
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
        expect(r.x).to eq 1
        expect(r.y).to eq 2
        expect(r.z).to eq 3
        expect(r.num_loads).to eq 1
      end
    end

    context "With an actual_value for the struct that sets y to x*2 and z to x*3" do
      with_struct(:MyResource) do
        attribute :x, identity: true
        attribute :y, default_value: proc { @actual_value }
        attribute :z
        def get


        end
      end
    end
  end
end
