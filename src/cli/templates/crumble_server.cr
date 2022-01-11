require "crumble"
require "./views/*"
require "./stimulus_controllers/*"
require "./resources/*"

StimulusInclude = {{ run("./stimulus_include.cr").stringify }}

Crumble::Server.start
