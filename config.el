;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq doom-theme 'doom-sourcerer)
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15))
;; fonte proporcional, usada no texto do markdown renderizado
;; (Adwaita Sans: derivada da Inter, desenhada para leitura em tela)
(setq doom-variable-pitch-font (font-spec :family "Adwaita Sans"))
(setq display-line-numbers-type 'relative)
(setq org-directory "~/org/")
(setq evil-split-window-below t evil-vsplit-window-right t)
(setq shell-file-name (executable-find "bash"))

(add-to-list 'default-frame-alist '(inhibit-double-buffering . t)) ;; prevent some cases of flickering
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
;;(fset 'rainbow-delimiters-mode #'ignore) ;; disable rainbow delimiters 💅
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


;;; Ortografia
;; hunspell com português e inglês juntos: as specs misturam pt-BR com termos
;; técnicos (endpoint, deploy, payload). O pt_BR vem do pacote hunspell-pt-BR.
;; Palavras aceitas com zg vão para o dicionario-pessoal.txt deste diretório.
(after! ispell
  (setq ispell-personal-dictionary (expand-file-name "dicionario-pessoal.txt" doom-user-dir))
  (ispell-set-spellchecker-params)
  (if (not (assoc "pt_BR" ispell-hunspell-dict-paths-alist))
      (message "Ortografia: falta o dicionário pt_BR (sudo dnf install hunspell-pt-BR)")
    (setq ispell-dictionary "pt_BR,en_US")
    (ispell-hunspell-add-multi-dic "pt_BR,en_US"))

  ;; o hunspell avisa no stderr quando não converte um caractere (o ⚠️, já que o
  ;; dicionário pt_BR é ISO8859-1); misturado à lista de palavras erradas, o
  ;; aviso aparecia no rodapé como "error - iconv ... word not found"
  (defadvice! my/ispell-discard-stderr-a (args)
    :filter-args #'ispell-call-process-region
    (let ((dest (nth 4 args)))
      (if (bufferp dest)
          (append (seq-take args 4) (list (list dest nil)) (nthcdr 5 args))
        args))))


;;; Web
;; templates Jinja do Flask (pastas templates*/): o motor django do web-mode
;; entende {% %} e {{ }}
(after! web-mode
  (add-to-list 'web-mode-engines-alist '("django" . "templates[^/]*/.+\\.html?\\'")))


;;; Markdown
;; .md abre renderizado no próprio buffer (markdown-modern): títulos com tamanhos
;; diferentes, tabelas desenhadas e ajustadas à janela, sem a marcação visível.
;; O elemento sob o cursor mostra o markdown cru para editar.
(defun my/markdown-toggle-rendering ()
  "Alterna entre o markdown renderizado (markdown-modern) e o fonte puro (markdown-mode)."
  (interactive)
  (if (derived-mode-p 'markdown-modern-mode)
      (markdown-mode)
    (markdown-modern-mode)))

(defun my/markdown-outline-search (&optional bound move backward looking-at)
  "Busca títulos markdown para o `outline', pulando `#' dentro de blocos de código."
  (let ((re "^\\(#\\{1,6\\}\\)[ \t]"))
    (if looking-at
        (and (looking-at re)
             (not (save-match-data (markdown-modern--fenced-code-block-at (point)))))
      (let ((orig (point)) found)
        (while (and (not found)
                    (if backward
                        (re-search-backward re bound t)
                      (re-search-forward re bound t)))
          (unless (save-match-data
                    (markdown-modern--fenced-code-block-at (match-beginning 0)))
            (setq found t)))
        (cond (found t)
              (move (goto-char (or bound (if backward (point-min) (point-max)))) nil)
              (t (goto-char orig) nil))))))

(defun my/markdown-fold-cycle ()
  "No título: dobra/desdobra como o TAB do org. Fora dele não faz nada (nunca insere texto)."
  (interactive)
  (when (outline-on-heading-p)
    (outline-cycle)))

(defvar my/markdown-column-width 120
  "Largura, em colunas, do texto do markdown renderizado (centralizado na janela).")

(defun my/markdown-center-column-h (&optional win)
  "Põe margens iguais dos dois lados da janela, deixando o texto numa coluna central."
  (let ((win (if (windowp win) win (get-buffer-window nil t))))
    (when (window-live-p win)
      (let* ((margins (window-margins win))
             (text (+ (window-body-width win) (or (car margins) 0) (or (cdr margins) 0)))
             (side (max 0 (/ (- text my/markdown-column-width) 2))))
        (unless (equal margins (cons side side))
          (set-window-margins win side side)
          ;; as tabelas são dimensionadas pela largura da janela: redesenha
          (with-current-buffer (window-buffer win) (jit-lock-refontify)))))))

(defvar my/markdown-heading-space '((1 . 1.2) (2 . 0.5) (3 . 0.3))
  "Espaço extra acima dos títulos, por nível, em alturas de linha.
Níveis fora da lista não ganham espaço.")

(defvar my/markdown-top-space 2.4
  "Altura da primeira linha do documento, em múltiplos da altura do título.
O que passa da altura do título vira a margem do topo.")

(defvar-local my/markdown-heading-space-timer nil)

(defun my/markdown-heading-space-refresh (&optional buf)
  "Põe um espaço acima de cada título, maior quanto mais alto o nível, e a
margem do topo do documento.
Vale com a seção aberta ou dobrada: na lista de títulos dobrados funciona
como um padding entre eles.  Nada disso é uma linha extra antes do título:
como a marcação `## ' fica escondida no começo da linha, uma linha extra ali
fazia o cursor ser desenhado no título de cima e o TAB abrir o de baixo."
  (with-current-buffer (or buf (current-buffer))
    (remove-overlays (point-min) (point-max) 'my/markdown-heading-space t)
    (save-excursion
      ;; margem do topo: a primeira linha na tela fica mais alta (o excesso do
      ;; line-height vai para cima do texto); com o título dobrado, essa linha
      ;; termina na primeira quebra de linha visível depois dele
      (goto-char (point-min))
      (if (looking-at "#\\{1,6\\}[ \t]")
          (let ((nl (line-end-position)))
            (while (and (< nl (point-max)) (invisible-p nl))
              (setq nl (next-single-char-property-change nl 'invisible)))
            (when (< nl (point-max))
              (let ((ov (make-overlay nl (1+ nl))))
                (overlay-put ov 'my/markdown-heading-space t)
                (overlay-put ov 'line-height (cons nil my/markdown-top-space)))))
        ;; documento que não começa com título: uma linha vazia antes dele
        (let ((ov (make-overlay (point-min) (point-min))))
          (overlay-put ov 'my/markdown-heading-space t)
          (overlay-put ov 'before-string (propertize "\n" 'face '(:height 2.5)))))
      (while (re-search-forward "^\\(#\\{1,6\\}\\)[ \t]" nil t)
        (let ((ratio (alist-get (length (match-string 1)) my/markdown-heading-space))
              (bol (match-beginning 0)))
          ;; o espaço fica embaixo da linha anterior (line-spacing na quebra de
          ;; linha antes do título), não numa linha extra: com uma linha extra
          ;; o cursor era desenhado no título de cima e o TAB abria o de baixo
          (when (and ratio
                     (> bol (point-min))
                     (not (save-match-data (markdown-modern--fenced-code-block-at bol))))
            (let ((ov (make-overlay (1- bol) bol)))
              (overlay-put ov 'my/markdown-heading-space t)
              (overlay-put ov 'line-spacing ratio))))))))

(defun my/markdown-heading-space-schedule-h (&rest _)
  "Recalcula o espaço dos títulos logo depois de uma edição ou dobra."
  (when (derived-mode-p 'markdown-modern-mode)
    (when (timerp my/markdown-heading-space-timer)
      (cancel-timer my/markdown-heading-space-timer))
    (setq my/markdown-heading-space-timer
          (run-with-timer 0.1 nil (lambda (buf)
                                    (when (buffer-live-p buf)
                                      (my/markdown-heading-space-refresh buf)))
                          (current-buffer)))))

(defun my/markdown-flyspell-check-word-p ()
  "Diz ao flyspell se checa a palavra antes do cursor.
Pula código (inline e em bloco), URLs e o texto que a renderização esconde
ou substitui, como a marcação e as tabelas."
  (let ((pos (1- (point))))
    (not (or (get-char-property pos 'display)
             (cl-some (lambda (ov)
                        (memq (overlay-get ov 'face)
                              '(markdown-modern-inline-code markdown-modern-link-url)))
                      (overlays-at pos))
             (save-excursion (goto-char pos) (thing-at-point 'url))
             (save-match-data (markdown-modern--fenced-code-block-at pos))))))

(use-package! markdown-modern
  :mode ("\\.md\\'" . markdown-modern-mode)
  :config
  ;; sem números de linha no markdown renderizado: numa tabela cada linha do
  ;; arquivo ocupa várias linhas na tela e o número caía na borda, não no texto
  ;; (SPC t l liga de volta no buffer atual)
  (add-hook 'markdown-modern-mode-hook #'doom-disable-line-numbers-h)

  ;; texto numa coluna central com margens iguais dos dois lados; sem o recuo
  ;; de 4 espaços que o pacote põe só à esquerda
  (setq markdown-modern-left-margin 0)
  (add-hook! 'markdown-modern-mode-hook
    (add-hook 'window-size-change-functions #'my/markdown-center-column-h nil t)
    (add-hook 'window-buffer-change-functions #'my/markdown-center-column-h nil t)
    (my/markdown-center-column-h))
  ;; margem do topo e espaço acima dos títulos (nível 1 > 2 > 3), para cada
  ;; seção começar visivelmente; recalculado ao editar e ao dobrar/desdobrar
  (add-hook! 'markdown-modern-mode-hook
    (my/markdown-heading-space-refresh)
    (add-hook 'after-change-functions #'my/markdown-heading-space-schedule-h nil t)
    (add-hook 'change-major-mode-hook
              (lambda () (remove-overlays (point-min) (point-max) 'my/markdown-heading-space t))
              nil t))
  (advice-add 'outline-flag-region :after #'my/markdown-heading-space-schedule-h)

  ;; com variable-pitch, os números de linha herdam a fonte proporcional e as
  ;; linhas sem número (bordas e células das tabelas) ficam deslocadas
  (add-hook! 'markdown-modern-mode-hook
    (face-remap-add-relative 'line-number 'fixed-pitch)
    (face-remap-add-relative 'line-number-current-line 'fixed-pitch))

  ;; a largura das tabelas não desconta a coluna de números de linha, então as
  ;; mais largas transbordavam a janela
  (defadvice! my/markdown-modern-table-width-a (cols)
    :filter-return #'markdown-modern-render--table-display-width
    (if-let* ((win (get-buffer-window)))
        (max 20 (- cols (ceiling (line-number-display-width t)
                                 (window-font-width win 'markdown-modern-table))))
      cols))

  ;; só mostra o markdown cru do elemento sob o cursor no modo de inserção;
  ;; no normal (lendo/navegando) tabelas, títulos e ênfases continuam renderizados
  (defadvice! my/markdown-modern-reveal-only-insert-a (fn pos)
    :around #'markdown-modern--markup-element-at
    (when (or (not (bound-and-true-p evil-local-mode))
              (memq evil-state '(insert replace emacs)))
      (funcall fn pos)))

  ;; bug do pacote: ao redesenhar um item de lista ele apaga só o item, mas
  ;; redesenha a lista inteira, e as bolinhas dos outros itens se acumulavam;
  ;; aqui a área apagada passa a cobrir tudo o que vai ser redesenhado
  (defadvice! my/markdown-modern-clear-whole-elements-a (fn start end)
    :around #'markdown-modern-render--render-region
    (when (and (not markdown-modern-render--rendering-p) markdown-modern--rendering-enabled)
      (dolist (el (markdown-modern-ts--elements-in-region start end))
        (setq start (min start (markdown-modern-node-start el))
              end (max end (markdown-modern-node-end el)))))
    (funcall fn start end))

  ;; com a marcação escondida (`## ' vira display ""), o Emacs empurra o cursor
  ;; para a linha de cima ao subir para um título, e ele caía na seção anterior
  (setq-hook! 'markdown-modern-mode-hook global-disable-point-adjustment t)

  ;; fold de seções como no org: o outline do Emacs passa a reconhecer os títulos
  ;; markdown, e os atalhos do módulo fold do Doom (za, zo, zc, zM, zR) funcionam
  (add-hook! 'markdown-modern-mode-hook
    (setq-local outline-regexp "#\\{1,6\\}[ \t]"
                outline-search-function #'my/markdown-outline-search
                outline-level (lambda () (save-excursion (forward-line 0) (skip-chars-forward "#"))))
    (outline-minor-mode +1))

  ;; corretor ortográfico: palavra errada fica sublinhada; ]s e [s pulam entre
  ;; os erros, z= mostra sugestões, zg aceita a palavra
  (when (modulep! :checkers spell +flyspell)
    (set-flyspell-predicate! 'markdown-modern-mode #'my/markdown-flyspell-check-word-p)
    (add-hook 'markdown-modern-mode-hook #'flyspell-mode))

  (map! :map markdown-modern-mode-map
        :n "TAB"     #'my/markdown-fold-cycle   ;; título: fechado -> subtítulos -> tudo
        :n [backtab] #'outline-cycle-buffer     ;; documento todo: títulos de topo -> todos os títulos -> tudo
        :m "]h"      #'markdown-modern-next-heading
        :m "[h"      #'markdown-modern-prev-heading
        :localleader
        "m" #'my/markdown-toggle-rendering            ;; SPC m m: fonte puro <-> renderizado
        "e" #'markdown-modern-toggle-element-at-point ;; mostra/esconde o cru do elemento
        "'" #'markdown-modern-edit-code-block
        "w" #'markdown-modern-toggle-truncate-lines)) ;; rolagem horizontal em vez de quebrar

(after! markdown-mode
  (map! :map markdown-mode-map
        :localleader
        "m" #'my/markdown-toggle-rendering))
