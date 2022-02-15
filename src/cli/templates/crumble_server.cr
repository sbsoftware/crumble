require "crumble"
require "./models/*"
require "./views/*"
require "./stimulus_controllers/*"
require "./resources/*"
require "./styles/*"

StimulusInclude = {{ run("./stimulus_include.cr").stringify }}

Crumble::Server.start
