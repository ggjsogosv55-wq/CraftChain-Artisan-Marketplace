;; Artisan Profile Registry Smart Contract
;; Verifies artisan credentials, traditional techniques, and cultural heritage craft backgrounds

;; Constants for error handling
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ARTISAN-EXISTS (err u101))
(define-constant ERR-ARTISAN-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u104))
(define-constant ERR-VERIFICATION-PENDING (err u105))
(define-constant ERR-INVALID-CRAFT-TYPE (err u106))
(define-constant ERR-CULTURAL-BACKGROUND-REQUIRED (err u107))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures
(define-map artisan-profiles
  { artisan-address: principal }
  {
    name: (string-ascii 100),
    craft-type: (string-ascii 50),
    cultural-background: (string-ascii 200),
    traditional-techniques: (list 10 (string-ascii 100)),
    years-experience: uint,
    verification-status: (string-ascii 20),
    reputation-score: uint,
    total-crafts: uint,
    registration-block: uint,
    last-activity: uint,
    verified-by: (optional principal),
    certifications: (list 5 (string-ascii 100))
  }
)

;; Verification authorities (can verify artisan profiles)
(define-map verification-authorities
  { authority: principal }
  {
    name: (string-ascii 100),
    specialization: (string-ascii 100),
    authorized: bool,
    verifications-count: uint
  }
)

;; Cultural heritage validators
(define-map cultural-validators
  { validator: principal }
  {
    culture-region: (string-ascii 100),
    expertise-areas: (list 5 (string-ascii 100)),
    validation-count: uint,
    active: bool
  }
)

;; Artisan skill endorsements
(define-map skill-endorsements
  { artisan: principal, endorser: principal }
  {
    skill-area: (string-ascii 50),
    endorsement-level: uint,
    comment: (string-ascii 200),
    block-height: uint
  }
)

;; Craft type registry
(define-map recognized-crafts
  { craft-name: (string-ascii 50) }
  {
    description: (string-ascii 200),
    cultural-origin: (string-ascii 100),
    required-techniques: (list 5 (string-ascii 100)),
    min-experience: uint,
    active: bool
  }
)

;; Public functions

;; Register a new artisan profile
(define-public (register-artisan 
    (name (string-ascii 100))
    (craft-type (string-ascii 50))
    (cultural-background (string-ascii 200))
    (traditional-techniques (list 10 (string-ascii 100)))
    (years-experience uint)
    (certifications (list 5 (string-ascii 100))))
  (let
    (
      (artisan-address tx-sender)
      (existing-profile (map-get? artisan-profiles { artisan-address: artisan-address }))
    )
    (asserts! (is-none existing-profile) ERR-ARTISAN-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-STATUS)
    (asserts! (> (len craft-type) u0) ERR-INVALID-CRAFT-TYPE)
    (asserts! (> (len cultural-background) u0) ERR-CULTURAL-BACKGROUND-REQUIRED)
    
    (ok (map-set artisan-profiles
      { artisan-address: artisan-address }
      {
        name: name,
        craft-type: craft-type,
        cultural-background: cultural-background,
        traditional-techniques: traditional-techniques,
        years-experience: years-experience,
        verification-status: "pending",
        reputation-score: u0,
        total-crafts: u0,
        registration-block: stacks-block-height,
        last-activity: stacks-block-height,
        verified-by: none,
        certifications: certifications
      }
    ))
  )
)

;; Verify an artisan profile (only by authorized verifiers)
(define-public (verify-artisan 
    (artisan-address principal)
    (verification-notes (string-ascii 200)))
  (let
    (
      (verifier tx-sender)
      (artisan-profile (unwrap! (map-get? artisan-profiles { artisan-address: artisan-address }) ERR-ARTISAN-NOT-FOUND))
      (authority (map-get? verification-authorities { authority: verifier }))
    )
    (asserts! (is-some authority) ERR-NOT-AUTHORIZED)
    (asserts! (get authorized (unwrap-panic authority)) ERR-NOT-AUTHORIZED)
    
    (map-set artisan-profiles
      { artisan-address: artisan-address }
      (merge artisan-profile {
        verification-status: "verified",
        verified-by: (some verifier),
        reputation-score: u50,
        last-activity: stacks-block-height
      })
    )
    
    ;; Update verifier statistics
    (map-set verification-authorities
      { authority: verifier }
      (merge (unwrap-panic authority) {
        verifications-count: (+ (get verifications-count (unwrap-panic authority)) u1)
      })
    )
    
    (ok true)
  )
)

;; Add verification authority (only contract owner)
(define-public (add-verification-authority
    (authority principal)
    (name (string-ascii 100))
    (specialization (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (ok (map-set verification-authorities
      { authority: authority }
      {
        name: name,
        specialization: specialization,
        authorized: true,
        verifications-count: u0
      }
    ))
  )
)

;; Add cultural validator
(define-public (add-cultural-validator
    (validator principal)
    (culture-region (string-ascii 100))
    (expertise-areas (list 5 (string-ascii 100))))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (ok (map-set cultural-validators
      { validator: validator }
      {
        culture-region: culture-region,
        expertise-areas: expertise-areas,
        validation-count: u0,
        active: true
      }
    ))
  )
)

;; Endorse artisan skills
(define-public (endorse-artisan-skill
    (artisan principal)
    (skill-area (string-ascii 50))
    (endorsement-level uint)
    (comment (string-ascii 200)))
  (let
    (
      (endorser tx-sender)
      (artisan-profile (unwrap! (map-get? artisan-profiles { artisan-address: artisan }) ERR-ARTISAN-NOT-FOUND))
      (endorser-profile (unwrap! (map-get? artisan-profiles { artisan-address: endorser }) ERR-NOT-AUTHORIZED))
    )
    (asserts! (is-eq (get verification-status endorser-profile) "verified") ERR-NOT-AUTHORIZED)
    (asserts! (>= (get reputation-score endorser-profile) u25) ERR-INSUFFICIENT-REPUTATION)
    (asserts! (<= endorsement-level u5) ERR-INVALID-STATUS)
    (asserts! (> endorsement-level u0) ERR-INVALID-STATUS)
    
    (ok (map-set skill-endorsements
      { artisan: artisan, endorser: endorser }
      {
        skill-area: skill-area,
        endorsement-level: endorsement-level,
        comment: comment,
        block-height: stacks-block-height
      }
    ))
  )
)

;; Update artisan activity and reputation
(define-public (update-artisan-activity (craft-completed bool))
  (let
    (
      (artisan tx-sender)
      (profile (unwrap! (map-get? artisan-profiles { artisan-address: artisan }) ERR-ARTISAN-NOT-FOUND))
      (reputation-bonus (if craft-completed u5 u1))
    )
      (ok (map-set artisan-profiles
      { artisan-address: artisan }
      (merge profile {
        last-activity: stacks-block-height,
        total-crafts: (if craft-completed 
                        (+ (get total-crafts profile) u1)
                        (get total-crafts profile)),
        reputation-score: (+ (get reputation-score profile) reputation-bonus)
      })
    ))
  )
)

;; Register recognized craft type
(define-public (register-craft-type
    (craft-name (string-ascii 50))
    (description (string-ascii 200))
    (cultural-origin (string-ascii 100))
    (required-techniques (list 5 (string-ascii 100)))
    (min-experience uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (ok (map-set recognized-crafts
      { craft-name: craft-name }
      {
        description: description,
        cultural-origin: cultural-origin,
        required-techniques: required-techniques,
        min-experience: min-experience,
        active: true
      }
    ))
  )
)

;; Read-only functions

;; Get artisan profile
(define-read-only (get-artisan-profile (artisan-address principal))
  (map-get? artisan-profiles { artisan-address: artisan-address })
)

;; Get verification authority info
(define-read-only (get-verification-authority (authority principal))
  (map-get? verification-authorities { authority: authority })
)

;; Get cultural validator info
(define-read-only (get-cultural-validator (validator principal))
  (map-get? cultural-validators { validator: validator })
)

;; Get skill endorsement
(define-read-only (get-skill-endorsement (artisan principal) (endorser principal))
  (map-get? skill-endorsements { artisan: artisan, endorser: endorser })
)

;; Get recognized craft info
(define-read-only (get-craft-info (craft-name (string-ascii 50)))
  (map-get? recognized-crafts { craft-name: craft-name })
)

;; Check if artisan is verified
(define-read-only (is-artisan-verified (artisan-address principal))
  (match (map-get? artisan-profiles { artisan-address: artisan-address })
    profile (is-eq (get verification-status profile) "verified")
    false
  )
)

;; Get artisan reputation score
(define-read-only (get-artisan-reputation (artisan-address principal))
  (match (map-get? artisan-profiles { artisan-address: artisan-address })
    profile (some (get reputation-score profile))
    none
  )
)

;; Check if principal is authorized verifier
(define-read-only (is-authorized-verifier (authority principal))
  (match (map-get? verification-authorities { authority: authority })
    authority-info (get authorized authority-info)
    false
  )
)

;; title: artisan-profile-registry
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

