require 'ostruct'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'

require 'www/favicon'

describe WWW::Favicon do
  before do
    @favicon = WWW::Favicon.new
  end

  it "should find from link element when rel is short" do
    @favicon.stub!(:request).and_return expect(:body => '<html><link rel="icon" href="/favicon_shortrel.ico" /></html>')
    @favicon.find('http://example.com/').should == 'http://example.com/favicon_shortrel.ico'
  end
  
  it "should find from link element when rel is upcase" do
    @favicon.stub!(:request).and_return expect(:body => '<html><link rel="Shortcut Icon" href="/favicon_shortrel.ico" /></html>')
    @favicon.find('http://example.com/').should == 'http://example.com/favicon_shortrel.ico'
  end
  
  it "should find absolute url from link element" do
    @favicon.stub!(:request).and_return expect(:body => '<html><link rel="shortcut icon" href="/favicon.ico" /></html>')
    @favicon.find('http://example.com/repos/').should == 'http://example.com/favicon.ico'
  end
  
  it "should find relative url from link element" do
    @favicon.stub!(:request).and_return expect(:body => '<html><link rel="shortcut icon" href="./chrome/common/trac.ico" /></html>')
    @favicon.find('http://example.com/repos/').should == 'http://example.com/repos/chrome/common/trac.ico'
  end
  
  it "should find from link element when href starts with http" do
    @favicon.stub!(:request).and_return expect(:body => '<html><link rel="shortcut icon" href="http://example.com/foo/favicon.ico" /></html>')
    @favicon.find('http://example.com/').should == 'http://example.com/foo/favicon.ico'
  end
  
  it "should find from default path" do
    @favicon.stub!(:request).and_return(expect(:body => '<html></html>'), expect(:code => '200'))
    @favicon.find('http://www.example.com/').should == 'http://www.example.com/favicon.ico'
  end
  
  it "should find from default path" do
    @favicon.stub!(:request).and_return(expect(:body => '<html></html>'), expect(:code => '404'))
    @favicon.find('http://example.com/').should be_nil
  end
end

def expect(attr)
  OpenStruct.new(attr)
end
