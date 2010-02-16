(display 4)

(define (fact x)
  (if (= x 0)
      1
      (* x (fact (- x 1)))))
 
(display (fact 6))
 
(define (add x)
  (lambda (y)
    (+ x y)))
 
(define add4 (add 4))
(define add5 (add 5))
 
(display (add4 3))
(display (add5 3))
