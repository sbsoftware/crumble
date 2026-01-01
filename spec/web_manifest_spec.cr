require "./spec_helper"
require "json"

module WebManifestPurposeSpec
  AppIcon = PNGFile.new("/icon.png", "fake")

  class SymbolPurposeManifest < Crumble::WebManifest
    name "Test"
    short_name "Test"

    icon AppIcon, sizes: "192x192", purpose: :maskable
  end

  class EnumPurposeManifest < Crumble::WebManifest
    name "Test"
    short_name "Test"

    icon AppIcon, sizes: "192x192", purpose: Crumble::WebManifest::IconPurpose::Monochrome
  end

  class MultiPurposeManifest < Crumble::WebManifest
    name "Test"
    short_name "Test"

    icon AppIcon,
      sizes: "192x192",
      purpose: {:monochrome, :maskable}
  end
end

describe Crumble::WebManifest do
  it "serializes icon purpose from a symbol" do
    json = JSON.parse(WebManifestPurposeSpec::SymbolPurposeManifest.to_json)
    icon = json["icons"].as_a.first
    icon["purpose"].as_s.should eq("maskable")
  end

  it "serializes icon purpose from the enum" do
    json = JSON.parse(WebManifestPurposeSpec::EnumPurposeManifest.to_json)
    icon = json["icons"].as_a.first
    icon["purpose"].as_s.should eq("monochrome")
  end

  it "serializes multiple icon purposes as a space-separated list" do
    json = JSON.parse(WebManifestPurposeSpec::MultiPurposeManifest.to_json)
    icon = json["icons"].as_a.first
    icon["purpose"].as_s.should eq("monochrome maskable")
  end
end
