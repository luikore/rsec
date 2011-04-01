module Arithmetic where
import Text.ParserCombinators.Parsec
import Text.ParserCombinators.Parsec.Expr
import Foreign.C.String

expr :: Parser Integer
expr = buildExpressionParser table factor
		<?> "expression"

table = [[op "*" (*) AssocLeft, op "/" div AssocLeft]
		,[op "+" (+) AssocLeft, op "-" (-) AssocLeft]
		]
		where
			op s f assoc = Infix (do{ string s; return f}) assoc

factor = do{char '('
			; x <- expr
			; char ')'
			; return x
		} <|> number <?> "simple expression"

number :: Parser Integer
number = do{ds <- many1 digit
			; return (read ds)
		} <?> "number"

calculate :: CString -> IO Int
calculate cs = do
	s <- peekCString cs
	(Right x) <- return $ parse expr "" s
	return (fromIntegral x)

donothing :: CString -> IO Int
donothing cs = return 0

foreign export stdcall calculate :: CString -> IO Int
foreign export stdcall donothing :: CString -> IO Int

