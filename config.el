;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-1337)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15))
(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")
(setq evil-split-window-below t evil-vsplit-window-right t)

(add-to-list 'default-frame-alist '(inhibit-double-buffering . t)) ;; prevent some cases of flickering
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(fset 'rainbow-delimiters-mode #'ignore) ;; disable rainbow delimiters 💅
(setq doom-scratch-initial-major-mode 'org-mode) ;; scratch buffer org mode

;;(setq scroll-step 1
;;      scroll-margin 3
;;      scroll-conservatively 101)

;;(setq pixel-scroll-precision-use-momentum t)
;;(pixel-scroll-precision-mode 1)


(setq mouse-wheel-scroll-amount '(1 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil) ;; desativa aceleração
(setq scroll-conservatively 101)
(setq scroll-margin 3)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;


(after! doom-modeline
  (setq doom-modeline-modal nil) ;; an evil mode indicator is redundant with cursor shape
  (setq doom-modeline-check-simple-format t)
  (setq doom-modeline-env-version t)
  )


(use-package! copilot-chat) ;; We define bindings below using the map! macro

;; (add-hook 'git-commit-setup-hook 'copilot-chat-insert-commit-message)
(setq copilot-chat-follow t)

(after! copilot-chat
  (set-popup-rule! "^\*Copilot Chat.*"
    :side 'right      ; Exibir no lado direito
    :size 0.33        ; Ocupar 33% da largura do frame
    :select t         ; Selecionar automaticamente a janela quando ela abrir
    :quit t           ; Torná-la "quit-able" (essencial para o ESC)
    :ttl nil))        ; Não fechar automaticamente (time-to-live)

;; accept completion from copilot and fallback to company
;; acredito que eu não esteja usando o company, mas sim o corfu (verificar em init.el)
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("<tab>" . 'copilot-accept-completion)
              ("TAB" . 'copilot-accept-completion)
              ("C-TAB" . 'copilot-accept-completion-by-word)
              ("C-<tab>" . 'copilot-accept-completion-by-word))
  :config
  ;; Fix for "copilot--infer-indentation-offset found no mode-specific indentation offset"
  (setq copilot-indentation-offset 2))

;;; Standardized Copilot Keybindings
(map! :leader
      :prefix ("z" . "Copilot") ;; SPC z
      ;; Chat Commands
      "c" #'copilot-chat
      "b" #'copilot-chat-chat-buffer
      "r" #'copilot-chat-chat-region
      ;; Yank Commands
      "y" #'copilot-chat-yank
      "Y" #'copilot-chat-yank-pop)


;; Customizations for copilot-chat, including commit message generation
(after! copilot-chat
  ;; Funções personalizadas para mensagens de commit do Copilot
  (defun my/copilot-insert-commit-message-en ()
    "Generate a commit message in English using Copilot."
    (interactive)
    (let ((copilot-chat-prompts
           (cons '("commit-message" . "Write a concise git commit message in the conventional commit format for the following diff. The message should be in English:\n\n{diff}")
                 (assq-delete-all "commit-message" copilot-chat-prompts))))
      (copilot-chat-insert-commit-message)))

  (defun my/copilot-insert-commit-message-pt-br ()
    "Generate a commit message in Brazilian Portuguese using Copilot."
    (interactive)
    (let ((copilot-chat-prompts
           (cons '("commit-message" . "Escreva uma mensagem de commit concisa no formato de conventional commit para o seguinte diff. A mensagem deve ser em português do Brasil:\n\n{diff}")
                 (assq-delete-all "commit-message" copilot-chat-prompts))))
      (copilot-chat-insert-commit-message)))

  ;; Adiciona os atalhos para as funções de commit no menu do Copilot
  (map! :leader
        :prefix ("z" . "Copilot")
        "m" #'my/copilot-insert-commit-message-en
        "M" #'my/copilot-insert-commit-message-pt-br))
