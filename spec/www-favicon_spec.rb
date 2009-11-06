require 'ostruct'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'

require 'www/favicon'

describe WWW::Favicon do
  before do
    @favicon = WWW::Favicon.new
    @htmls = [
              '<html><link rel="icon" href="/foo/favicon.ico" /></html>',
              '<html><link rel="Shortcut Icon" href="/foo/favicon.ico" /></html>',
              '<html><link rel="shortcut icon" href="/foo/favicon.ico" /></html>',
              '<html><link rel="shortcut icon" href="./foo/favicon.ico" /></html>',
              '<html><link rel="shortcut icon" href="http://example.com/foo/favicon.ico" /></html>',
             ]
  end

  it "should find from url" do
    @htmls.each do |html|
      @favicon.stub!(:request).and_return expectaction(:body => html)
      @favicon.find('http://example.com/').should == 'http://example.com/foo/favicon.ico'
    end
  end
  
  it "should find from html and url" do
    @htmls.each do |html|
      @favicon.find_from_html(html, 'http://example.com/').should == 'http://example.com/foo/favicon.ico'
    end
  end
  
  it "should find from default path" do
    @favicon.stub!(:request).and_return(expectaction(:body => '<html></html>'), expectaction(:code => '200'))
    @favicon.find('http://www.example.com/').should == 'http://www.example.com/favicon.ico'

    @favicon.stub!(:request).and_return(expectaction(:code => '200'))
    @favicon.find_from_html('<html></html>', 'http://www.example.com/').should == 'http://www.example.com/favicon.ico'
  end
  
  it "should not find from default path" do
    @favicon.stub!(:request).and_return(expectaction(:body => '<html></html>'), expectaction(:code => '404'))
    @favicon.find('http://example.com/').should be_nil

    @favicon.stub!(:request).and_return(expectaction(:code => '404'))
    @favicon.find_from_html('<html></html>', 'http://www.example.com/').should be_nil
  end
end

describe WWW::Favicon, 'with the :verify => true option' do
  before do
    @favicon = WWW::Favicon.new(:verify => true)
    @favicon.stub!(:request).and_return(expectaction(:body => '<html></html>'), expectaction(:code => '200'))
  end

  it "should validate the favicon_url" do
    @favicon.should_receive(:valid_favicon_url?).with('http://www.example.com/favicon.ico')
    @favicon.find('http://www.example.com/')
  end

  it "should return nil if #valid_favicon_url? returns false" do
    @favicon.stub!(:valid_favicon_url?).and_return(false)
    @favicon.find('http://www.example.com/').should be_nil
  end

  it "should return the url if #valid_favicon_url? returns true" do
    @favicon.stub!(:valid_favicon_url?).and_return(true)
    @favicon.find('http://www.example.com/').should == 'http://www.example.com/favicon.ico'
  end

  describe '#valid_favicon_url?' do
    before do
      @url = 'http://www.example.com/favicon.ico'
      @response = expectaction(:code => '200', :body => 'an image', :content_type => 'image/jpeg')
      @favicon.stub!(:request).and_return(@response)
    end

    it 'should return true if it is valid' do
      @favicon.valid_favicon_url?(@url).should == true
    end

    it 'should return false if the code is not 200' do
      @response.code = '500'
      @favicon.valid_favicon_url?(@url).should == false
    end

    it 'should return false if the body is blank' do
      @response.body = ''
      @favicon.valid_favicon_url?(@url).should == false
    end

    it 'should return false if the content type is not an image content type' do
      @response.content_type = 'application/xml'
      @favicon.valid_favicon_url?(@url).should == false
    end
  end
end

def expectaction(attr)
  OpenStruct.new(attr)
end
