;; Fill Level Monitoring Contract
;; Tracks container capacity in the smart city waste management system

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map containers
  { container-id: uint }
  {
    collection-point-id: uint,
    capacity: uint,
    current-fill-level: uint,
    last-updated-at: uint,
    reporter: principal
  }
)

(define-map authorized-reporters principal bool)

;; Public functions
(define-public (register-container (container-id uint) (collection-point-id uint) (capacity uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u200))
    (map-insert containers
      { container-id: container-id }
      {
        collection-point-id: collection-point-id,
        capacity: capacity,
        current-fill-level: u0,
        last-updated-at: block-height,
        reporter: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (update-fill-level (container-id uint) (fill-level uint))
  (let ((container-data (unwrap! (map-get? containers { container-id: container-id }) (err u201))))
    (asserts! (is-authorized-reporter tx-sender) (err u202))
    (asserts! (<= fill-level (get capacity container-data)) (err u203))
    (map-set containers
      { container-id: container-id }
      (merge container-data {
        current-fill-level: fill-level,
        last-updated-at: block-height,
        reporter: tx-sender
      })
    )
    (ok true)
  )
)

(define-public (add-reporter (reporter principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u204))
    (map-set authorized-reporters reporter true)
    (ok true)
  )
)

(define-public (remove-reporter (reporter principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u205))
    (map-delete authorized-reporters reporter)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-authorized-reporter (user principal))
  (default-to false (map-get? authorized-reporters user))
)

(define-read-only (get-container (container-id uint))
  (map-get? containers { container-id: container-id })
)

(define-read-only (get-fill-percentage (container-id uint))
  (let ((container-data (map-get? containers { container-id: container-id })))
    (if (is-some container-data)
      (let ((data (unwrap-panic container-data)))
        (/ (* (get current-fill-level data) u100) (get capacity data))
      )
      u0
    )
  )
)

(define-read-only (needs-collection (container-id uint) (threshold uint))
  (let ((fill-percentage (get-fill-percentage container-id)))
    (>= fill-percentage threshold)
  )
)
