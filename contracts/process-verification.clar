;; Processing Verification Contract
;; Records waste treatment in the smart city system

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map processing-facilities
  { facility-id: uint }
  {
    name: (string-utf8 100),
    location: (string-utf8 100),
    capacity: uint,
    active: bool
  }
)

(define-map waste-batches
  { batch-id: uint }
  {
    facility-id: uint,
    weight: uint,
    waste-type: (string-utf8 50),
    processed: bool,
    processing-method: (string-utf8 50),
    processed-at: uint,
    verifier: principal
  }
)

(define-map authorized-processors principal bool)

;; Public functions
(define-public (register-facility (facility-id uint) (name (string-utf8 100)) (location (string-utf8 100)) (capacity uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u400))
    (map-insert processing-facilities
      { facility-id: facility-id }
      {
        name: name,
        location: location,
        capacity: capacity,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (register-waste-batch (batch-id uint) (facility-id uint) (weight uint) (waste-type (string-utf8 50)))
  (begin
    (asserts! (is-authorized-processor tx-sender) (err u401))
    (asserts! (is-some (map-get? processing-facilities { facility-id: facility-id })) (err u402))
    (map-insert waste-batches
      { batch-id: batch-id }
      {
        facility-id: facility-id,
        weight: weight,
        waste-type: waste-type,
        processed: false,
        processing-method: "",
        processed-at: u0,
        verifier: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (verify-processing (batch-id uint) (processing-method (string-utf8 50)))
  (let ((batch-data (unwrap! (map-get? waste-batches { batch-id: batch-id }) (err u403))))
    (asserts! (is-authorized-processor tx-sender) (err u404))
    (asserts! (not (get processed batch-data)) (err u405))
    (map-set waste-batches
      { batch-id: batch-id }
      (merge batch-data {
        processed: true,
        processing-method: processing-method,
        processed-at: block-height,
        verifier: tx-sender
      })
    )
    (ok true)
  )
)

(define-public (add-processor (processor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u406))
    (map-set authorized-processors processor true)
    (ok true)
  )
)

(define-public (remove-processor (processor principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u407))
    (map-delete authorized-processors processor)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-authorized-processor (user principal))
  (default-to false (map-get? authorized-processors user))
)

(define-read-only (get-facility (facility-id uint))
  (map-get? processing-facilities { facility-id: facility-id })
)

(define-read-only (get-waste-batch (batch-id uint))
  (map-get? waste-batches { batch-id: batch-id })
)

(define-read-only (is-batch-processed (batch-id uint))
  (let ((batch-data (map-get? waste-batches { batch-id: batch-id })))
    (if (is-some batch-data)
      (get processed (unwrap-panic batch-data))
      false
    )
  )
)
