require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

gem 'fastercsv', '>=1.2.3'
require 'fastercsv'

if HAS_SQLITE3
  describe DataMapper::Type do

    before do

      @adapter = repository(:sqlite3).adapter

      module TypeTests
        class Impostor < DataMapper::Type
          primitive String
        end

        class Coconut
          include DataMapper::Resource

          storage_names[:sqlite3] = 'coconuts'

          property :id, Integer, :serial => true
          property :faked, Impostor
          property :active, Boolean
          property :note, Text
        end
      end

      TypeTests::Coconut.auto_migrate!(:sqlite3)

      @document = <<-EOS.margin
        NAME, RATING, CONVENIENCE
        Freebird's, 3, 3
        Whataburger, 1, 5
        Jimmy John's, 3, 4
        Mignon, 5, 2
        Fuzi Yao's, 5, 1
        Blue Goose, 5, 1
      EOS

      @stuff = YAML::dump({ 'Happy Cow!' => true, 'Sad Cow!' => false })

      @active = true
      @note = "This is a note on our ol' guy bob"
    end

    it "should instantiate an object with custom types" do
      coconut = TypeTests::Coconut.new(:faked => 'bob', :active => @active, :note => @note)
      coconut.faked.should == 'bob'
      coconut.active.should be_a_kind_of(TrueClass)
      coconut.note.should be_a_kind_of(String)
    end

    it "should CRUD an object with custom types" do
      repository(:sqlite3) do
        coconut = TypeTests::Coconut.new(:faked => 'bob', :active => @active, :note => @note)
        coconut.save.should be_true
        coconut.id.should_not be_nil

        fred = TypeTests::Coconut[coconut.id]
        fred.faked.should == 'bob'
        fred.active.should be_a_kind_of(TrueClass)
        fred.note.should be_a_kind_of(String)

        note = "Seems like bob is just mockin' around"
        fred.note = note

        fred.save.should be_true

        active = false
        fred.active = active

        fred.save.should be_true

        # Can't call coconut.reload! since coconut.collection isn't setup.
        mac = TypeTests::Coconut[fred.id]
        mac.active.should == active
        mac.note.should == note
      end
    end

    it "should respect paranoia with a datetime" do

      class Lime
        include DataMapper::Resource
        property :id, Integer, :serial => true
        property :color, String
        property :deleted_at, DataMapper::Types::ParanoidDateTime
      end

      Lime.auto_migrate!(:sqlite3)

      repository(:sqlite3) do
        lime = Lime.new
        lime.color = 'green'

        lime.save
        lime.destroy
        # lime.deleted_at.should_not be_nil
        repository(:sqlite3).adapter.query("SELECT count(*) from limes").first.should_not == 0
        repository(:sqlite3).adapter.query("SELECT * from limes").should_not be_empty

        repository(:sqlite3).adapter.execute("DROP TABLE limes")
      end
    end

    it "should respect paranoia with a datetime" do

      class Lime
        include DataMapper::Resource
        property :id, Integer, :serial => true
        property :color, String
        property :deleted_at, DataMapper::Types::ParanoidBoolean
      end

      Lime.auto_migrate!(:sqlite3)

      repository(:sqlite3) do
        lime = Lime.new
        lime.color = 'green'

        lime.save
        lime.destroy
        # lime.deleted_at.should_not be_nil
        repository(:sqlite3).adapter.query("SELECT count(*) from limes").first.should_not == 0
        repository(:sqlite3).adapter.query("SELECT * from limes").should_not be_empty

        repository(:sqlite3).adapter.execute("DROP TABLE limes")
      end
    end


    after do
      @adapter = repository(:sqlite3).adapter
      @adapter.execute("DROP TABLE coconuts")
    end
  end
end
