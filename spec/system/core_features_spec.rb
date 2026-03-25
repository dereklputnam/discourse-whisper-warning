# frozen_string_literal: true

RSpec.describe "Core features" do
  before { upload_theme_or_component }

  it_behaves_like "having working core features"
end

RSpec.describe "Whisper Warning" do
  fab!(:admin)
  fab!(:moderator)
  fab!(:user)
  fab!(:group)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category: category) }

  before do
    upload_theme_or_component
    group.add(moderator)
    sign_in(moderator)
  end

  def open_composer
    visit "/t/#{topic.slug}/#{topic.id}"
    find("#reply-button").click
    expect(page).to have_css("#reply-control")
  end

  def enable_whisper
    find(".composer-actions .toggle-toolbar").click if page.has_css?(".composer-actions .toggle-toolbar")
    find(".composer-actions").click
    find("[data-value='toggle_whisper']").click
  end

  context "with default settings" do
    it "shows the warning button for users who can whisper" do
      open_composer
      expect(page).to have_css(".whisper-hint")
    end

    it "shows the public icon when not whispering" do
      open_composer
      expect(page).to have_css(".whisper-hint.public")
    end

    it "shows the whispering icon when whispering" do
      open_composer
      enable_whisper
      expect(page).to have_css(".whisper-hint.whispering")
    end
  end

  context "with whisper_only enabled" do
    before { theme.update_setting(:whisper_only, true) }

    it "hides the button when composing a public reply" do
      open_composer
      expect(page).not_to have_css(".whisper-hint")
    end

    it "shows the button when composing a whisper" do
      open_composer
      enable_whisper
      expect(page).to have_css(".whisper-hint.whispering")
    end
  end

  context "with restrict_to_groups set" do
    before { theme.update_setting(:restrict_to_groups, group.name) }

    it "shows for users in the specified group" do
      open_composer
      expect(page).to have_css(".whisper-hint")
    end

    it "hides for users not in the specified group" do
      sign_in(admin)
      open_composer
      expect(page).not_to have_css(".whisper-hint")
    end
  end

  context "with restrict_to_categories set" do
    fab!(:other_topic) { Fabricate(:topic) }

    before { theme.update_setting(:restrict_to_categories, category.slug) }

    it "shows when replying in a specified category" do
      open_composer
      expect(page).to have_css(".whisper-hint")
    end

    it "hides when replying in an unspecified category" do
      visit "/t/#{other_topic.slug}/#{other_topic.id}"
      find("#reply-button").click
      expect(page).not_to have_css(".whisper-hint")
    end
  end
end