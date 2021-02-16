require 'test_helper'

class BasicTest < ActiveSupport::TestCase  # :nodoc:

  def test_version
    refute_nil ActiveRecord::ConnectionAdapters::PostGISAdapter::VERSION
  end

  def test_postgis_available
    assert_equal 'PostGIS', SpatialModel.connection.adapter_name
    assert SpatialModel.connection.postgis_lib_version.start_with? '2.'
  end

  def test_arel_visitor
    visitor = Arel::Visitors::PostGIS.new(SpatialModel.connection)
    node = RGeo::ActiveRecord::SpatialConstantNode.new('POINT (1.0 2.0)')
    collector = Arel::Collectors::PlainString.new
    visitor.accept(node, collector)
    assert_equal "ST_GeomFromEWKT('POINT (1.0 2.0)')", collector.value
  end

  def test_set_and_get_point
    create_model
    obj = SpatialModel.new
    assert_nil obj.latlon
    obj.latlon = factory.point(1.0, 2.0)
    assert_equal factory.point(1.0, 2.0), obj.latlon
    assert_equal 3785, obj.latlon.srid
  end

  def test_set_and_get_point_from_wkt
    create_model
    obj = SpatialModel.new
    assert_nil obj.latlon
    obj.latlon = 'POINT(1 2)'
    assert_equal factory.point(1.0, 2.0), obj.latlon
    assert_equal 3785, obj.latlon.srid
  end

  def test_save_and_load_point
    create_model
    obj = SpatialModel.new
    obj.latlon = factory.point(1.0, 2.0)
    obj.save!
    id = obj.id
    obj2 = SpatialModel.find(id)
    assert_equal factory.point(1.0, 2.0), obj2.latlon
    assert_equal 3785, obj2.latlon.srid
    # assert_equal true, RGeo::Geos.is_geos?(obj2.latlon)
  end

  def test_save_and_load_geographic_point
    create_model
    obj = SpatialModel.new
    obj.latlon_geo = geographic_factory.point(1.0, 2.0)
    obj.save!
    id = obj.id
    obj2 = SpatialModel.find(id)
    assert_equal geographic_factory.point(1.0, 2.0), obj2.latlon_geo
    assert_equal 4326, obj2.latlon_geo.srid
    # assert_equal false, RGeo::Geos.is_geos?(obj2.latlon_geo)
  end

  def test_save_and_load_point_from_wkt
    create_model
    obj = SpatialModel.new
    obj.latlon = 'POINT(1 2)'
    obj.save!
    id = obj.id
    obj2 = SpatialModel.find(id)
    assert_equal factory.point(1.0, 2.0), obj2.latlon
    assert_equal 3785, obj2.latlon.srid
  end

  def test_set_point_bad_wkt
    create_model
    obj = SpatialModel.create(latlon: 'POINT (x)')
    assert_nil obj.latlon
  end

  def test_set_point_wkt_wrong_type
    create_model
    assert_raises(ActiveRecord::StatementInvalid) do
      SpatialModel.create(latlon: 'LINESTRING(1 2, 3 4, 5 6)')
    end
  end

  def test_custom_factory
    klass = SpatialModel
    klass.connection.create_table(:spatial_test, force: true) do |t|
      t.st_point(:latlon, srid: 4326)
    end
    factory = RGeo::Geographic.simple_mercator_factory
    klass.class_eval do
      set_rgeo_factory_for_column(:latlon, factory)
    end
    assert_equal factory, klass.rgeo_factory_for_column(:latlon)
    object = klass.new
    assert_equal factory, object.class.rgeo_factory_for_column(:latlon)
  end

  def test_readme_example
    klass = SpatialModel
    klass.connection.create_table(:spatial_models, force: true) do |t|
      t.column(:shape, :geometry)
      t.line_string(:path, srid: 3785)
      t.st_point(:latlon, geographic: true)
    end
    klass.reset_column_information
    assert_includes klass.columns.map(&:name), "shape"
    klass.connection.change_table(:spatial_models) do |t|
      t.index(:latlon, using: :gist)
    end
    klass.class_eval do
      self.rgeo_factory_generator = RGeo::Geos.method(:factory)
      set_rgeo_factory_for_column(:latlon, RGeo::Geographic.spherical_factory)
    end
    object = klass.new
    object.latlon = 'POINT(-122 47)'
    point = object.latlon
    assert_equal 47, point.latitude
    object.shape = point
    # assert_equal true, RGeo::Geos.is_geos?(object.shape)
  end

  def test_point_to_json
    create_model
    obj = SpatialModel.new
    assert_match(/"latlon":null/, obj.to_json)
    obj.latlon = factory.point(1.0, 2.0)
    assert_match(/"latlon":"POINT\s\(1\.0\s2\.0\)"/, obj.to_json)
  end

  def test_custom_column
    create_model
    rec = SpatialModel.new
    rec.latlon = 'POINT(0 0)'
    rec.save
    refute_nil SpatialModel.select("CURRENT_TIMESTAMP as ts").first.ts
  end

  private

  def create_model
    SpatialModel.connection.create_table(:spatial_models, force: true) do |t|
      t.column 'latlon', :st_point, srid: 3785
      t.column 'latlon_geo', :st_point, srid: 4326, geographic: true
    end
    SpatialModel.reset_column_information
  end
end

