require 'rails_helper'

RSpec.describe AssetSearcher do

  #------------------------------------------------------------------------------
  #
  # Instance Methods
  #
  #------------------------------------------------------------------------------
  it 'should be able to search for assets put in service in a particular year' do
    searcher = AssetSearcher.new();
    expect(searcher.attributes).to include(:in_service_date)
    expect(searcher.attributes).to include(:in_service_date_comparator)

    searcher = AssetSearcher.new(:in_service_date => 2014, :in_service_date_comparator => '0')
    expect(searcher.data). to eq(Asset.where('in_service_year = 2014'))
  end

  it 'should be able to search for assets put in service in after a particular year' do
    searcher = AssetSearcher.new();
    expect(searcher.attributes).to include(:in_service_date)
    expect(searcher.attributes).to include(:in_service_date_comparator)

    searcher = AssetSearcher.new(:in_service_date => 2014, :in_service_date_comparator => '1')
    expect(searcher.data). to eq(Asset.where('in_service_year > 2014'))
  end

  it 'should be able to search for assets put in service in before a particular year' do
    searcher = AssetSearcher.new();
    expect(searcher.attributes).to include(:in_service_date)
    expect(searcher.attributes).to include(:in_service_date_comparator)

    searcher = AssetSearcher.new(:in_service_date => 2014, :in_service_date_comparator => '-1')
    expect(searcher.data). to eq(Asset.where('in_service_year < 2014'))
  end

  it 'should be able to search for assets equal to a particular book value' do
    searcher = AssetSearcher.new();
    expect(searcher.attributes).to include(:book_value)
    expect(searcher.attributes).to include(:book_value_comparator)

    searcher = AssetSearcher.new(:book_value => 30000, :book_value_comparator => '0')
    expect(searcher.data). to eq(Asset.where('book_value = 30000'))
  end

  it 'should be able to search for assets greater than a particular book value' do
    searcher = AssetSearcher.new();
    expect(searcher.attributes).to include(:book_value)
    expect(searcher.attributes).to include(:book_value_comparator)

    searcher = AssetSearcher.new(:book_value => 30000, :book_value_comparator => '1')
    expect(searcher.data). to eq(Asset.where('book_value > 30000'))
  end

  it 'should be able to search for assets less than a particular book value' do
    searcher = AssetSearcher.new();
    expect(searcher.attributes).to include(:book_value)
    expect(searcher.attributes).to include(:book_value_comparator)

    searcher = AssetSearcher.new(:book_value => 30000, :book_value_comparator => '-1')
    expect(searcher.data). to eq(Asset.where('book_value < 30000'))
  end

  it 'should be able to search for assets by funding type' do
    searcher = AssetSearcher.new();
    expect(searcher.attributes).to include(:fta_funding_type_id)

    searcher = AssetSearcher.new(:fta_funding_type_id => 1)
    expect(searcher.data). to eq(Asset.where(fta_funding_type_id: 1))
  end
end
