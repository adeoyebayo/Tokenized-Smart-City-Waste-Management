;; Collection Point Verification Contract
;; Validates waste receptacles in the smart city system

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map collection-points
  { point-id: uint }
  {
    location: (string-utf8 100),
    verified: bool,
    last-verified-at: uint,
    verifier: principal
  }
)

(define-map authorized-verifiers principal bool)

;; Public functions
(define-public (register-collection-point (point-id uint) (location (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (map-insert collection-points
      { point-id: point-id }
      {
        location: location,
        verified: false,
        last-verified-at: u0,
        verifier: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (verify-collection-point (point-id uint))
  (let ((point-data (unwrap! (map-get? collection-points { point-id: point-id }) (err u101))))
    (asserts! (is-authorized tx-sender) (err u102))
    (map-set collection-points
      { point-id: point-id }
      (merge point-data {
        verified: true,
        last-verified-at: block-height,
        verifier: tx-sender
      })
    )
    (ok true)
  )
)

(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u103))
    (map-set authorized-verifiers verifier true)
    (ok true)
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u104))
    (map-delete authorized-verifiers verifier)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-authorized (user principal))
  (default-to false (map-get? authorized-verifiers user))
)

(define-read-only (get-collection-point (point-id uint))
  (map-get? collection-points { point-id: point-id })
)

(define-read-only (is-point-verified (point-id uint))
  (let ((point-data (map-get? collection-points { point-id: point-id })))
    (if (is-some point-data)
      (get verified (unwrap-panic point-data))
      false
    )
  )
)
