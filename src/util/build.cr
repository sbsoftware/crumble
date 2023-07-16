class Object
  macro build(&blk)
    {{@type}}.new(
      {% if blk.body.is_a?(Assign) %}
        {{blk.body.target}}: {{blk.body.value}}
      {% elsif blk.body.is_a?(Call) %}
        {% if blk.body.block %}
          {{blk.body.name}}: begin
                               {{blk.body.block.body}}
                             end
        {% else %}
          {{pp "#{@type}.build: #{blk.body.name} needs a block or assignment"}}
        {% end %}
      {% elsif blk.body.is_a?(Expressions) %}
        {% for exp, index in blk.body.expressions %}
          {% if exp.is_a?(Assign) %}
            {{exp.target}}: {{exp.value}}{{",".id if index < blk.body.expressions.size - 1}}
          {% elsif exp.is_a?(Call) %}
            {% if exp.block %}
              {{exp.name}}: begin
                              {{exp.block.body}}
                            end{{",".id if index < blk.body.expressions.size - 1}}
            {% else %}
              {{pp "#{@type}.build: #{exp.name} needs a block or assignment"}}
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    )
  end
end
