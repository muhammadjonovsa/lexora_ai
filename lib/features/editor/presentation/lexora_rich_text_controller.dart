import 'package:flutter/material.dart';

class LexoraRichTextController extends TextEditingController {
  TextStyle? baseStyle;

  LexoraRichTextController({String? text}) : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    baseStyle = style ?? Theme.of(context).textTheme.bodyLarge;
    final List<TextSpan> children = [];
    
    // Parse text line by line to support headings and lists properly
    final lines = text.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineChildren = _parseLine(line, baseStyle!);
      
      // Append a newline character for all lines except the last one
      if (i < lines.length - 1) {
        children.add(TextSpan(children: lineChildren));
        children.add(const TextSpan(text: '\n'));
      } else {
        children.add(TextSpan(children: lineChildren));
      }
    }

    return TextSpan(style: baseStyle, children: children);
  }

  // Parse a single line for heading and inline styles
  List<TextSpan> _parseLine(String line, TextStyle currentStyle) {
    TextStyle lineStyle = currentStyle;
    String content = line;
    List<TextSpan> lineChildren = [];

    // 1. Check for Headings at the start of the line
    if (line.startsWith('# ')) {
      lineStyle = currentStyle.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        height: 1.4,
      );
      // Softly color the header syntax marker
      lineChildren.add(TextSpan(
        text: '# ',
        style: TextStyle(color: lineStyle.color?.withOpacity(0.2), fontWeight: FontWeight.normal),
      ));
      content = line.substring(2);
    } else if (line.startsWith('## ')) {
      lineStyle = currentStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        height: 1.4,
      );
      lineChildren.add(TextSpan(
        text: '## ',
        style: TextStyle(color: lineStyle.color?.withOpacity(0.2), fontWeight: FontWeight.normal),
      ));
      content = line.substring(3);
    } else if (line.startsWith('### ')) {
      lineStyle = currentStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.4,
      );
      lineChildren.add(TextSpan(
        text: '### ',
        style: TextStyle(color: lineStyle.color?.withOpacity(0.2), fontWeight: FontWeight.normal),
      ));
      content = line.substring(4);
    } else if (line.startsWith('* ') || line.startsWith('- ')) {
      // Bullet list syntax styling
      lineChildren.add(TextSpan(
        text: '• ',
        style: TextStyle(color: currentStyle.primaryColor, fontWeight: FontWeight.bold),
      ));
      content = line.substring(2);
    } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
      // Numbered list syntax styling
      final match = RegExp(r'^(\d+\.\s)').firstMatch(line);
      if (match != null) {
        final marker = match.group(1)!;
        lineChildren.add(TextSpan(
          text: marker,
          style: TextStyle(color: currentStyle.primaryColor, fontWeight: FontWeight.bold),
        ));
        content = line.substring(marker.length);
      }
    } else if (line.startsWith('> ')) {
      // Blockquote syntax styling
      lineStyle = currentStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: currentStyle.color?.withOpacity(0.7),
      );
      lineChildren.add(TextSpan(
        text: '┃ ',
        style: TextStyle(color: currentStyle.primaryColor.withOpacity(0.6), fontWeight: FontWeight.bold),
      ));
      content = line.substring(2);
    }

    // 2. Parse inline formats (Bold, Italic, Code, Underline)
    final inlineChildren = _parseInlineStyles(content, lineStyle);
    lineChildren.addAll(inlineChildren);

    return lineChildren;
  }

  // Parse inline styles within a block using flat matching
  List<TextSpan> _parseInlineStyles(String text, TextStyle baseLineStyle) {
    final List<TextSpan> spans = [];
    
    // Flat tokenization regex: matches **bold**, *italic*, `code`, _underline_
    final regExp = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`|_[^_]+_)');
    
    int currentOffset = 0;
    
    final matches = regExp.allMatches(text);
    
    for (final match in matches) {
      // Add plain text before match
      if (match.start > currentOffset) {
        spans.add(TextSpan(
          text: text.substring(currentOffset, match.start),
          style: baseLineStyle,
        ));
      }
      
      final matchedText = match.group(0)!;
      
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        // Bold
        final innerText = matchedText.substring(2, matchedText.length - 2);
        spans.add(TextSpan(
          text: '**',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
        spans.add(TextSpan(
          text: innerText,
          style: baseLineStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(
          text: '**',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        // Italic
        final innerText = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: '*',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
        spans.add(TextSpan(
          text: innerText,
          style: baseLineStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(
          text: '*',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
      } else if (matchedText.startsWith('_') && matchedText.endsWith('_')) {
        // Underline
        final innerText = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: '_',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
        spans.add(TextSpan(
          text: innerText,
          style: baseLineStyle.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(TextSpan(
          text: '_',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        // Code/Monospace
        final innerText = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: '`',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
        spans.add(TextSpan(
          text: innerText,
          style: baseLineStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: baseLineStyle.color?.withOpacity(0.05),
          ),
        ));
        spans.add(TextSpan(
          text: '`',
          style: TextStyle(color: baseLineStyle.color?.withOpacity(0.2)),
        ));
      }
      
      currentOffset = match.end;
    }
    
    // Add remaining plain text
    if (currentOffset < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentOffset),
        style: baseLineStyle,
      ));
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: baseLineStyle)] : spans;
  }
}
extension TextStyleExt on TextStyle {
  Color get primaryColor => color ?? Colors.indigo;
}
