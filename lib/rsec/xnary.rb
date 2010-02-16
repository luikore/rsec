# coding: utf-8
# ------------------------------------------------------------------------------
# x-nary combinators

module Rsec
  class Xnary < Array
    include ::Rsec
  end

  class LSeq < Xnary
    def _parse ctx
      inject(LAssocNode.new) do |s_node, e|
        res = e._parse ctx
        return nil unless res
        s_node.assoc res
      end
    end
  end

  class RSeq < Xnary
    def _parse ctx
      inject(RAssocNode.new) do |s_node, e|
        res = e._parse ctx
        return nil unless res
        s_node.assoc res
      end
    end
  end

  class Or < Xnary
    def _parse ctx
      save_point = ctx.pos
      each do |e|
        res = e._parse ctx
        return res if res
        ctx.pos = save_point
      end
      nil
    end
  end # class
end
