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

  describe '#find' do
    before do
      @favicon.stub!(:valid_favicon_url?).and_return(true)
    end

    it "should find from url" do
      @htmls.each do |html|
        @favicon.should_receive(:request).and_return expectaction(:body => html)
        @favicon.find('http://example.com/').should == 'http://example.com/foo/favicon.ico'
      end
    end
    
    it "should find from html and url" do
      @htmls.each do |html|
        @favicon.find_from_html(html, 'http://example.com/').should == 'http://example.com/foo/favicon.ico'
      end
    end
  
    it "should find from default path" do
      @favicon.should_receive(:request).and_return(expectaction(:body => '<html></html>'))
      @favicon.find('http://www.example.com/').should == 'http://www.example.com/favicon.ico'

      @favicon.should_not_receive(:request)
      @favicon.find_from_html('<html></html>', 'http://www.example.com/').should == 'http://www.example.com/favicon.ico'
    end

    it "should validate url" do
      @favicon.stub!(:request).and_return(expectaction(:body => '<html></html>'))
      @favicon.should_receive(:valid_favicon_url?)
      @favicon.find('http://www.example.com/')
    end

    it "should return nil if #valid_favicon_url? returns false" do
      @favicon.should_receive(:request).and_return(expectaction(:body => '<html></html>'))
      @favicon.should_receive(:valid_favicon_url?).and_return(false)
      @favicon.find('http://www.example.com/').should be_nil
    end
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

    it 'should follow redirect' do
      @favicon.stub!(:request).and_return(@response)
      @response.should_receive(:kind_of?).and_return(true)
      @response.should_receive(:'[]').with('Location').and_return('http://example.com/')
      @response.should_receive(:kind_of?).and_return(false)

      @favicon.valid_favicon_url?(@url).should == true
    end

    it 'should return false if redirect limit is exceeded' do
      @favicon.stub!(:request).and_return(@response)

      10.times do |i|
        @response.should_receive(:kind_of?).and_return(true)
        @response.should_receive(:'[]').with('Location').and_return("http://example.com/#{i}")
      end

      @favicon.valid_favicon_url?(@url).should == false
    end
  end
end

def expectaction(attr)
  OpenStruct.new(attr)
end
