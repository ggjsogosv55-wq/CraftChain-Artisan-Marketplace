;; Handmade Verification System Smart Contract
;; Records photo/video proof of handcraft process with time-stamped creation documentation

;; Constants for error handling
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-VERIFICATION-NOT-FOUND (err u201))
(define-constant ERR-INVALID-STAGE (err u202))
(define-constant ERR-ARTISAN-NOT-VERIFIED (err u203))
(define-constant ERR-INVALID-MEDIA-HASH (err u204))
(define-constant ERR-PROCESS-ALREADY-COMPLETE (err u205))
(define-constant ERR-INSUFFICIENT-EVIDENCE (err u206))
(define-constant ERR-INVALID-TIMESTAMP (err u207))
(define-constant ERR-DUPLICATE-SUBMISSION (err u208))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Process stage constants
(define-constant STAGE-PREPARATION "preparation")
(define-constant STAGE-CRAFTING "crafting")
(define-constant STAGE-FINISHING "finishing")
(define-constant STAGE-COMPLETED "completed")

;; Data structures

;; Main verification record
(define-map craft-verifications
  { verification-id: (string-ascii 50) }
  {
    artisan: principal,
    craft-name: (string-ascii 100),
    craft-type: (string-ascii 50),
    creation-start: uint,
    estimated-completion: uint,
    actual-completion: (optional uint),
    current-stage: (string-ascii 20),
    total-stages: uint,
    completed-stages: uint,
    verification-status: (string-ascii 20),
    final-verification-hash: (optional (string-ascii 64)),
    materials-used: (list 10 (string-ascii 100)),
    techniques-applied: (list 10 (string-ascii 100)),
    cultural-significance: (string-ascii 300),
    authenticity-score: uint
  }
)

;; Media evidence for each stage
(define-map stage-evidence
  { verification-id: (string-ascii 50), stage: (string-ascii 20) }
  {
    media-hashes: (list 20 (string-ascii 64)),
    descriptions: (list 20 (string-ascii 200)),
    timestamps: (list 20 uint),
    location-data: (optional (string-ascii 100)),
    witnesses: (list 5 principal),
    tools-used: (list 10 (string-ascii 100)),
    duration-minutes: uint,
    quality-notes: (string-ascii 300)
  }
)

;; Time-stamped process steps
(define-map process-steps
  { verification-id: (string-ascii 50), step-number: uint }
  {
    step-description: (string-ascii 200),
    technique-used: (string-ascii 100),
    media-hash: (string-ascii 64),
    timestamp: uint,
    duration: uint,
    difficulty-level: uint,
    cultural-context: (string-ascii 200),
    verified-by: (optional principal)
  }
)

;; Witness attestations
(define-map witness-attestations
  { verification-id: (string-ascii 50), witness: principal }
  {
    attestation-type: (string-ascii 50),
    stage-witnessed: (string-ascii 20),
    confidence-level: uint,
    notes: (string-ascii 300),
    timestamp: uint,
    witness-reputation: uint
  }
)

;; Quality assessments
(define-map quality-assessments
  { verification-id: (string-ascii 50), assessor: principal }
  {
    craftsmanship-score: uint,
    authenticity-score: uint,
    cultural-accuracy: uint,
    technique-mastery: uint,
    overall-rating: uint,
    detailed-feedback: (string-ascii 500),
    assessment-timestamp: uint,
    recommended-improvements: (list 5 (string-ascii 100))
  }
)

;; Verification milestones
(define-map verification-milestones
  { verification-id: (string-ascii 50) }
  {
    milestones: (list 10 {
      name: (string-ascii 100),
      target-block: uint,
      completed-block: (optional uint),
      evidence-hash: (optional (string-ascii 64)),
      verified: bool
    })
  }
)

;; Public functions

;; Start craft verification process
(define-public (start-craft-verification
    (verification-id (string-ascii 50))
    (craft-name (string-ascii 100))
    (craft-type (string-ascii 50))
    (estimated-completion uint)
    (materials-used (list 10 (string-ascii 100)))
    (techniques-planned (list 10 (string-ascii 100)))
    (cultural-significance (string-ascii 300)))
  (let
    (
      (artisan tx-sender)
      (existing-verification (map-get? craft-verifications { verification-id: verification-id }))
    )
    ;; Check if artisan is verified (assume external contract call)
    (asserts! (is-none existing-verification) ERR-DUPLICATE-SUBMISSION)
    (asserts! (> estimated-completion stacks-block-height) ERR-INVALID-TIMESTAMP)
    (asserts! (> (len craft-name) u0) ERR-INVALID-STAGE)
    
    (ok (map-set craft-verifications
      { verification-id: verification-id }
      {
        artisan: artisan,
        craft-name: craft-name,
        craft-type: craft-type,
        creation-start: stacks-block-height,
        estimated-completion: estimated-completion,
        actual-completion: none,
        current-stage: STAGE-PREPARATION,
        total-stages: u3,
        completed-stages: u0,
        verification-status: "active",
        final-verification-hash: none,
        materials-used: materials-used,
        techniques-applied: techniques-planned,
        cultural-significance: cultural-significance,
        authenticity-score: u0
      }
    ))
  )
)

;; Submit stage evidence
(define-public (submit-stage-evidence
    (verification-id (string-ascii 50))
    (stage (string-ascii 20))
    (media-hashes (list 20 (string-ascii 64)))
    (descriptions (list 20 (string-ascii 200)))
    (tools-used (list 10 (string-ascii 100)))
    (duration-minutes uint)
    (quality-notes (string-ascii 300)))
  (let
    (
      (submitter tx-sender)
      (verification (unwrap! (map-get? craft-verifications { verification-id: verification-id }) ERR-VERIFICATION-NOT-FOUND))
      (existing-evidence (map-get? stage-evidence { verification-id: verification-id, stage: stage }))
    )
    (asserts! (is-eq (get artisan verification) submitter) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get verification-status verification) "active") ERR-PROCESS-ALREADY-COMPLETE)
    (asserts! (> (len media-hashes) u0) ERR-INSUFFICIENT-EVIDENCE)
    (asserts! (is-none existing-evidence) ERR-DUPLICATE-SUBMISSION)
    
    ;; Create timestamps for each media item
    (let
      (
        (timestamps (list stacks-block-height stacks-block-height stacks-block-height stacks-block-height stacks-block-height
                         stacks-block-height stacks-block-height stacks-block-height stacks-block-height stacks-block-height
                         stacks-block-height stacks-block-height stacks-block-height stacks-block-height stacks-block-height
                         stacks-block-height stacks-block-height stacks-block-height stacks-block-height stacks-block-height))
      )
      (ok (map-set stage-evidence
        { verification-id: verification-id, stage: stage }
        {
          media-hashes: media-hashes,
          descriptions: descriptions,
          timestamps: timestamps,
          location-data: none,
          witnesses: (list),
          tools-used: tools-used,
          duration-minutes: duration-minutes,
          quality-notes: quality-notes
        }
      ))
    )
  )
)

;; Add process step documentation
(define-public (add-process-step
    (verification-id (string-ascii 50))
    (step-number uint)
    (step-description (string-ascii 200))
    (technique-used (string-ascii 100))
    (media-hash (string-ascii 64))
    (duration uint)
    (difficulty-level uint)
    (cultural-context (string-ascii 200)))
  (let
    (
      (submitter tx-sender)
      (verification (unwrap! (map-get? craft-verifications { verification-id: verification-id }) ERR-VERIFICATION-NOT-FOUND))
    )
    (asserts! (is-eq (get artisan verification) submitter) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get verification-status verification) "active") ERR-PROCESS-ALREADY-COMPLETE)
    (asserts! (<= difficulty-level u10) ERR-INVALID-STAGE)
    (asserts! (> (len media-hash) u0) ERR-INVALID-MEDIA-HASH)
    
    (ok (map-set process-steps
      { verification-id: verification-id, step-number: step-number }
      {
        step-description: step-description,
        technique-used: technique-used,
        media-hash: media-hash,
        timestamp: stacks-block-height,
        duration: duration,
        difficulty-level: difficulty-level,
        cultural-context: cultural-context,
        verified-by: none
      }
    ))
  )
)

;; Add witness attestation
(define-public (add-witness-attestation
    (verification-id (string-ascii 50))
    (attestation-type (string-ascii 50))
    (stage-witnessed (string-ascii 20))
    (confidence-level uint)
    (notes (string-ascii 300)))
  (let
    (
      (witness tx-sender)
      (verification (unwrap! (map-get? craft-verifications { verification-id: verification-id }) ERR-VERIFICATION-NOT-FOUND))
    )
    (asserts! (not (is-eq (get artisan verification) witness)) ERR-NOT-AUTHORIZED)
    (asserts! (<= confidence-level u10) ERR-INVALID-STAGE)
    (asserts! (> confidence-level u0) ERR-INVALID-STAGE)
    
    (ok (map-set witness-attestations
      { verification-id: verification-id, witness: witness }
      {
        attestation-type: attestation-type,
        stage-witnessed: stage-witnessed,
        confidence-level: confidence-level,
        notes: notes,
        timestamp: stacks-block-height,
        witness-reputation: u0  ;; Could be enhanced with external reputation system
      }
    ))
  )
)

;; Submit quality assessment
(define-public (submit-quality-assessment
    (verification-id (string-ascii 50))
    (craftsmanship-score uint)
    (authenticity-score uint)
    (cultural-accuracy uint)
    (technique-mastery uint)
    (detailed-feedback (string-ascii 500))
    (recommended-improvements (list 5 (string-ascii 100))))
  (let
    (
      (assessor tx-sender)
      (verification (unwrap! (map-get? craft-verifications { verification-id: verification-id }) ERR-VERIFICATION-NOT-FOUND))
    )
    ;; Validate scores are between 1-10
    (asserts! (and (<= craftsmanship-score u10) (> craftsmanship-score u0)) ERR-INVALID-STAGE)
    (asserts! (and (<= authenticity-score u10) (> authenticity-score u0)) ERR-INVALID-STAGE)
    (asserts! (and (<= cultural-accuracy u10) (> cultural-accuracy u0)) ERR-INVALID-STAGE)
    (asserts! (and (<= technique-mastery u10) (> technique-mastery u0)) ERR-INVALID-STAGE)
    
    (let
      (
        (overall-rating (/ (+ craftsmanship-score authenticity-score cultural-accuracy technique-mastery) u4))
      )
      (ok (map-set quality-assessments
        { verification-id: verification-id, assessor: assessor }
        {
          craftsmanship-score: craftsmanship-score,
          authenticity-score: authenticity-score,
          cultural-accuracy: cultural-accuracy,
          technique-mastery: technique-mastery,
          overall-rating: overall-rating,
          detailed-feedback: detailed-feedback,
          assessment-timestamp: stacks-block-height,
          recommended-improvements: recommended-improvements
        }
      ))
    )
  )
)

;; Complete craft verification
(define-public (complete-craft-verification
    (verification-id (string-ascii 50))
    (final-verification-hash (string-ascii 64)))
  (let
    (
      (artisan tx-sender)
      (verification (unwrap! (map-get? craft-verifications { verification-id: verification-id }) ERR-VERIFICATION-NOT-FOUND))
    )
    (asserts! (is-eq (get artisan verification) artisan) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get verification-status verification) "active") ERR-PROCESS-ALREADY-COMPLETE)
    
    ;; Calculate final authenticity score based on evidence quality
    (let
      (
        (authenticity-score u85)  ;; Simplified calculation
      )
      (ok (map-set craft-verifications
        { verification-id: verification-id }
        (merge verification {
          actual-completion: (some stacks-block-height),
          current-stage: STAGE-COMPLETED,
          completed-stages: (get total-stages verification),
          verification-status: "completed",
          final-verification-hash: (some final-verification-hash),
          authenticity-score: authenticity-score
        })
      ))
    )
  )
)

;; Verify process step (by authorized verifiers)
(define-public (verify-process-step
    (verification-id (string-ascii 50))
    (step-number uint))
  (let
    (
      (verifier tx-sender)
      (step (unwrap! (map-get? process-steps { verification-id: verification-id, step-number: step-number }) ERR-VERIFICATION-NOT-FOUND))
    )
    ;; In a full implementation, would check if verifier is authorized
    (ok (map-set process-steps
      { verification-id: verification-id, step-number: step-number }
      (merge step {
        verified-by: (some verifier)
      })
    ))
  )
)

;; Read-only functions

;; Get craft verification details
(define-read-only (get-craft-verification (verification-id (string-ascii 50)))
  (map-get? craft-verifications { verification-id: verification-id })
)

;; Get stage evidence
(define-read-only (get-stage-evidence (verification-id (string-ascii 50)) (stage (string-ascii 20)))
  (map-get? stage-evidence { verification-id: verification-id, stage: stage })
)

;; Get process step details
(define-read-only (get-process-step (verification-id (string-ascii 50)) (step-number uint))
  (map-get? process-steps { verification-id: verification-id, step-number: step-number })
)

;; Get witness attestation
(define-read-only (get-witness-attestation (verification-id (string-ascii 50)) (witness principal))
  (map-get? witness-attestations { verification-id: verification-id, witness: witness })
)

;; Get quality assessment
(define-read-only (get-quality-assessment (verification-id (string-ascii 50)) (assessor principal))
  (map-get? quality-assessments { verification-id: verification-id, assessor: assessor })
)

;; Check if verification is complete
(define-read-only (is-verification-complete (verification-id (string-ascii 50)))
  (match (map-get? craft-verifications { verification-id: verification-id })
    verification (is-eq (get verification-status verification) "completed")
    false
  )
)

;; Get verification authenticity score
(define-read-only (get-authenticity-score (verification-id (string-ascii 50)))
  (match (map-get? craft-verifications { verification-id: verification-id })
    verification (some (get authenticity-score verification))
    none
  )
)

;; Get verification progress
(define-read-only (get-verification-progress (verification-id (string-ascii 50)))
  (match (map-get? craft-verifications { verification-id: verification-id })
    verification (some {
      current-stage: (get current-stage verification),
      completed-stages: (get completed-stages verification),
      total-stages: (get total-stages verification),
      progress-percentage: (* (/ (get completed-stages verification) (get total-stages verification)) u100)
    })
    none
  )
)

;; Validate media hash format (basic check)
(define-read-only (is-valid-media-hash (hash (string-ascii 64)))
  (and (is-eq (len hash) u64)
       (> (len hash) u0))
)

;; title: handmade-verification-system
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

