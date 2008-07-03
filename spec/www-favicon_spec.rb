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
      @favicon.stub!(:request).and_return expect(:body => html)
      @favicon.find('http://example.com/').should == 'http://example.com/foo/favicon.ico'
    end
  end
  
  it "should find from html and url" do
    @htmls.each do |html|
      @favicon.find_from_html(html, 'http://example.com/').should == 'http://example.com/foo/favicon.ico'
    end
  end
  
  it "should find from default path" do
    @favicon.stub!(:request).and_return(expect(:body => '<html></html>'), expect(:code => '200'))
    @favicon.find('http://www.example.com/').should == 'http://www.example.com/favicon.ico'

    @favicon.stub!(:request).and_return(expect(:code => '200'))
    @favicon.find_from_html('<html></html>', 'http://www.example.com/').should == 'http://www.example.com/favicon.ico'
  end
  
  it "should not find from default path" do
    @favicon.stub!(:request).and_return(expect(:body => '<html></html>'), expect(:code => '404'))
    @favicon.find('http://example.com/').should be_nil

    @favicon.stub!(:request).and_return(expect(:code => '404'))
    @favicon.find_from_html('<html></html>', 'http://www.example.com/').should be_nil
  end
end

def expect(attr)
  OpenStruct.new(attr)
end
