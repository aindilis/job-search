(global-set-key "\C-c\C-s\C-f" 'system-ie-quick-locate)

(defun system-ie-quick-locate ()
 "Open right to the spot you want"
 (interactive)
 (let* (
	(item (substring-no-properties (thing-at-point 'filename)))
	(file (progn
	       (string-match "^\\(.+\\)-\\([0-9]+\\)$" item)
	       (match-string 1 item)))
	(offset (match-string 2 item))
	)
  (find-file file)
  (beginning-of-buffer)
  (forward-char (string-to-int offset))
  ))
 