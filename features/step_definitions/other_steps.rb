When(/^I try to fabricate "([^"]*)"$/) do |fabricator_name|
  @fabricator_name = fabricator_name
end

Then(/^it should tell me that it isn't defined$/) do
  step "1 #{@fabricator_name}"
rescue StandardError => e
  e.message.should == "No Fabricator defined for '#{@fabricator_name}'"
end
