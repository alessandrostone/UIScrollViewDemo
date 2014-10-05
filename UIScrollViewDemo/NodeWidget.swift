//
//  Node.swift
//  UIScrollViewDemo
//
//  Created by Simon Gladman on 28/09/2014.
//  Copyright (c) 2014 Simon Gladman. All rights reserved.
//

import UIKit

class NodeWidget: UIControl
{
    var node: NodeVO!
    let label: UILabel = UILabel(frame: CGRectZero)
    
    let fadeAnimationDuration = 0.3
    
    required init(frame: CGRect, node: NodeVO)
    {
        super.init(frame: frame)
        
        self.node = node
    }

    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func didMoveToSuperview()
    {
        alpha = 0
        
        backgroundColor = UIColor.blueColor()
        
        layer.borderColor = UIColor.yellowColor().CGColor
        layer.borderWidth = 3
        layer.cornerRadius = 10
        
        label.frame = bounds.rectByInsetting(dx: 5, dy: 5)
        
        label.numberOfLines = 0
        populateLabel()
        addSubview(label)
        
        let pan = UIPanGestureRecognizer(target: self, action: "panHandler:");
        addGestureRecognizer(pan)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: "longHoldHandler:")
        addGestureRecognizer(longPress)
     
        NodesPM.addObserver(self, selector: "populateLabel", notificationType: .NodeUpdated)
        NodesPM.addObserver(self, selector: "nodeSelected:", notificationType: .NodeSelected)
        NodesPM.addObserver(self, selector: "populateLabel", notificationType: .NodeCreated)
        NodesPM.addObserver(self, selector: "relationshipCreationModeChanged:", notificationType: .RelationshipCreationModeChanged)
        NodesPM.addObserver(self, selector: "relationshipsChanged:", notificationType: .RelationshipsChanged)
        
        UIView.animateWithDuration(fadeAnimationDuration, animations: {self.alpha = 1})
    }
    
    var relationshipCreationCandidate: Bool = false
    {
        didSet
        {
            if NodesPM.relationshipCreationMode
            {
                if relationshipCreationCandidate && !(NodesPM.selectedNode! == node)
                {
                    UIView.animateWithDuration(fadeAnimationDuration, animations: {self.backgroundColor = UIColor.cyanColor()})
                    label.textColor = UIColor.blueColor()
                }
                else
                {
                    UIView.animateWithDuration(fadeAnimationDuration, animations: {self.alpha = 0.5})
                    enabled = false
                }
            }
            else
            {
                UIView.animateWithDuration(fadeAnimationDuration, animations: {self.alpha = 1.0})
                enabled = true
            
                setWidgetColors(NodesPM.selectedNode!)
            }
        }
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent)
    {
        if NodesPM.relationshipCreationMode && relationshipCreationCandidate
        {
            let touch = (touches.allObjects[0] as UITouch).locationInView(self)
            NodesPM.preferredInputIndex = touch.x < self.frame.width / 2 ? 0 : 1
            
            NodesPM.selectedNode = node
        }
        else if !NodesPM.relationshipCreationMode
        {
            NodesPM.selectedNode = node
            NodesPM.isDragging = true
        }
    }
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent)
    {
        NodesPM.isDragging = false
    }
    
    func relationshipCreationModeChanged(value : AnyObject)
    {
        let relationshipCreationMode = value.object as Bool
        
        relationshipCreationCandidate = node.nodeType == NodeTypes.Operator
    }
    
    func relationshipsChanged(value: AnyObject)
    {
        populateLabel()
    }

    func populateLabel()
    {
        label.textAlignment = NSTextAlignment.Center
        
        if node.nodeType == NodeTypes.Operator
        {
            let valueAsString = node.inputNodes.count > 1 ? NSString(format: "%.2f", node.value) : "??"
            
            let lhs = node.inputNodes.count > 0 ? NSString(format: "%.2f", node.inputNodes[0].value) : "??"
            let rhs = node.inputNodes.count > 1 ? NSString(format: "%.2f", node.inputNodes[1].value) : "??"
            
            label.text = "\(lhs) \(node.nodeOperator.toRaw()) \(rhs)\n\n\(valueAsString)"
        }
        else
        {
            let valueAsString = NSString(format: "%.2f", node.value);
            
            label.text = "\(valueAsString)"
        }
    }
    
    func nodeSelected(value : AnyObject)
    {
        let selectedNode = value.object as NodeVO
       
        setWidgetColors(selectedNode)
    }
    
    func setWidgetColors(selectedNode: NodeVO)
    {
        let targetColor = selectedNode == node ? UIColor.yellowColor() : UIColor.blueColor()
        
        UIView.animateWithDuration(fadeAnimationDuration, animations: {self.backgroundColor = targetColor})
        
        label.textColor = selectedNode == node ? UIColor.blueColor() : UIColor.whiteColor()
    }
    
    func longHoldHandler(recognizer: UILongPressGestureRecognizer)
    {
        NodesPM.relationshipCreationMode = true
    }
    
    func panHandler(recognizer: UIPanGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizerState.Changed
        {
            let gestureLocation = recognizer.locationInView(self)
            
            frame.offset(dx: gestureLocation.x - frame.width / 2, dy: gestureLocation.y - frame.height / 2)
            
            NodesPM.moveSelectedNode(CGPoint(x: frame.origin.x, y: frame.origin.y))
        }
        else if recognizer.state == UIGestureRecognizerState.Ended
        {
            NodesPM.isDragging = false
        }
    }
  
}


