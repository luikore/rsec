# coding: utf-8
# ------------------------------------------------------------------------------
# x-nary combinators

module Rsec
  class Xnary < Array
    include ::Rsec
  end

  # sequence combinator<br/>
  # result in an array (LAssocNode)
  class LSeq < Xnary
    def _parse ctx
      inject(LAssocNode.new) do |s_node, e|
        res = e._parse ctx
        return nil unless res
        s_node.assoc res
      end
    end
  end

  # sequence combinator<br/>
  # result in an array (RAssocNode)
  class RSeq < Xnary
    def _parse ctx
      inject(RAssocNode.new) do |s_node, e|
        res = e._parse ctx
        return nil unless res
        s_node.assoc res
      end
    end
  end

  # or combinator<br/>
  # result in on of the members, or nil
  class Or < Xnary
    def _parse ctx
      save_point = ctx.pos
      each do |e|
        res = e._parse ctx
        return res if res
        ctx.pos = save_point
      end
      nil # don't forget to fail it when none of the elements matches
    end
  end # class
end
