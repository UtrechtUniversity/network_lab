defmodule NetworkLab.Propositions.Proposition do
    
    # this is a mess, but it's because I don't want to mess up the
    # pretest fields while we're going into the real experiment
    defstruct [
        :id, :title, :true, :false, :post_is_false, 
        :post_intended_as_liberal, :show_version,
        :lib, :fake
    ]

end