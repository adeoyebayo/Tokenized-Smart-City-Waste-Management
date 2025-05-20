;; Route Optimization Contract
;; Plans efficient collection paths for waste management

(define-data-var contract-owner principal tx-sender)

;; Data structures
(define-map routes
  { route-id: uint }
  {
    name: (string-utf8 50),
    points: (list 20 uint),
    distance: uint,
    estimated-time: uint,
    last-updated: uint,
    active: bool
  }
)

(define-map vehicle-assignments
  { vehicle-id: uint }
  {
    route-id: uint,
    driver: principal,
    start-time: uint,
    end-time: uint,
    completed: bool
  }
)

(define-map authorized-planners principal bool)

;; Public functions
(define-public (create-route (route-id uint) (name (string-utf8 50)) (points (list 20 uint)) (distance uint) (estimated-time uint))
  (begin
    (asserts! (is-authorized-planner tx-sender) (err u300))
    (map-insert routes
      { route-id: route-id }
      {
        name: name,
        points: points,
        distance: distance,
        estimated-time: estimated-time,
        last-updated: block-height,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (update-route (route-id uint) (points (list 20 uint)) (distance uint) (estimated-time uint))
  (let ((route-data (unwrap! (map-get? routes { route-id: route-id }) (err u301))))
    (asserts! (is-authorized-planner tx-sender) (err u302))
    (map-set routes
      { route-id: route-id }
      (merge route-data {
        points: points,
        distance: distance,
        estimated-time: estimated-time,
        last-updated: block-height
      })
    )
    (ok true)
  )
)

(define-public (assign-vehicle (vehicle-id uint) (route-id uint) (driver principal) (start-time uint))
  (begin
    (asserts! (is-authorized-planner tx-sender) (err u303))
    (asserts! (is-some (map-get? routes { route-id: route-id })) (err u304))
    (map-set vehicle-assignments
      { vehicle-id: vehicle-id }
      {
        route-id: route-id,
        driver: driver,
        start-time: start-time,
        end-time: u0,
        completed: false
      }
    )
    (ok true)
  )
)

(define-public (complete-route (vehicle-id uint))
  (let ((assignment (unwrap! (map-get? vehicle-assignments { vehicle-id: vehicle-id }) (err u305))))
    (asserts! (or (is-eq tx-sender (get driver assignment)) (is-authorized-planner tx-sender)) (err u306))
    (map-set vehicle-assignments
      { vehicle-id: vehicle-id }
      (merge assignment {
        end-time: block-height,
        completed: true
      })
    )
    (ok true)
  )
)

(define-public (add-planner (planner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u307))
    (map-set authorized-planners planner true)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-authorized-planner (user principal))
  (default-to false (map-get? authorized-planners user))
)

(define-read-only (get-route (route-id uint))
  (map-get? routes { route-id: route-id })
)

(define-read-only (get-vehicle-assignment (vehicle-id uint))
  (map-get? vehicle-assignments { vehicle-id: vehicle-id })
)

(define-read-only (get-active-routes)
  ;; In a real implementation, this would return a list of active routes
  ;; Simplified for this example
  true
)
