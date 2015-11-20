require 'spec_helper'
describe 'delorean' do

  context 'with defaults for all parameters' do
    it { should contain_class('delorean') }
  end
end
